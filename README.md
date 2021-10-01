Note: This repo is for archival purposes only
---

![GMThreads](https://github.com/snakedeveloper/gmthreads/blob/main/gmthreads.png?raw=true)

Last update (30 dec 2009):
> Features:
> - GM8 support
> - Added thread_wait function, with which you can wait for a specified thread until it finishes executing the code
> - Now you can check whether an error occured in a given thread
> - Library has been rewritten to MASM
> - Source released (on LGPL)
>
> Compatibility issues:
> - Some functions has been renamed (thread_priority, thread_affinity_mask, thread_ideal_processor, thread_num_of_processors)
> - thread_last_error and thread_is_suspended functions has been removed.
> - Now when creating a thread you must close its handle with thread_close function. This allows you to retrieve an error code after the thread terminates (thread_get_error).

# What is it?

GMThreads is a DLL library, which can execute given GML code in threads. Actually, this is an experiment and it needs to be tested.

> A THREAD in computer science is short for a thread of execution. Threads are a way for a program to fork (or split) itself into two or more simultaneously (or pseudo-simultaneously) running tasks. Threads and processes differ from one operating system to another but, in general, a thread is contained inside a process and different threads in the same process share some resources while different processes do not.
> Read more...

In what these threads can be useful ?

Well, the code in threads is executed in the background, even when the game window is minimized, moved, displays a message `show_message`, room changes etc. With threads you can, for example, load resources at runtime and main game window will not freeze (FPS may decrease, but this also depends on the priority of the thread)

# DLL functions
`thread_init( filename )` - Initializes GMThreads. Optionally, You can specify path to GMThreads DLL (default: GMThreads.dll).   
`thread_create( GMLCode, Suspended? )` - Creates a thread with task to execute given GML code. If second argument is set to 1 (true) then created thread will be suspended. Returns thread handle, which can be used by functions listed below.   
`thread_suspend( ThreadHandle )` - Suspends thread. Returns 0 if error occured, otherwise 1.   
`thread_resume( ThreadHandle )` - Resumes thread. Returns 0 if error occured, otherwise 1.    
   
`thread_set_priority( ThreadHandle, Priority )` - Changes given thread's priority. Returns 0 if error occured, otherwise 1.   
Argument "priority" can be set to:   
  0 - Idle   
  1 - Low   
  2 - Below normal   
  3 - Normal (default)   
  4 - Above normal   
  5 - High   
  6 - Realtime   
  
`thread_get_priority( ThreadHandle )` - Returns thread's priority or -1 if error occured.   
   
`thread_get_error()` - Returns error code of the specified thread. Error code is set after the thread terminates.
Error codes:
  -1 = Invalid handle specified   
  0 = No error occured   
  1 = Game maker error (not existing variables/objects, array index out of bounds etc) or other unexpected error.   
     
     
`thread_terminate( ThreadHandle )` - Forces termination of given thread. Returns 0 if error occured, otherwise 1. Warning: Threads terminated with this function are unable to free used resources, causing memory leaks.   
`thread_is_running( ThreadHandle )` - Checks whether thread is running.   
`thread_set_affinity( ThreadHandle, Mask )` - Sets affinity mask to specified thread.   
`thread_set_processor( ThreadHandle, ProcessorNum )` - Sets preferred processor for specified thread.   
`thread_get_cpucount()` - Returns number of processors.   
`thread_wait( Thread Handle, Timeout )` - Waits until the specified thread will finish executing the code or specified timeout interval elapses. Timeout argument specifies time in miliseconds to wait until the thread terminates. If you pass -1 to the parameter the function will return only when the thread terminates.   

# How to use
Creating a thread:
New thread can be created with thread_create function. Returned value (thread's handle) should be stored in a variable in order to be able to control it later.
```
my_thread = thread_create( "repeat (1000) global.variable += 1;", 1 ); // create thread (suspended)
if ( my_thread ) {
  thread_set_priority( my_thread, 2 ); // Change priority to "below normal"
  thread_resume( my_thread ); // resume thread
} else
  show_message( "Could not create a thread." );
```

That code will create a new thread with lower priority or show an message if function fails.
In the GML code you can define variables ( local_variable = 0... ), but they cannot be accessed from other objects ( even that one, which call that function ), except global variables. After code execution thread will be terminated.

You can use the while loop to run the code infinitely
```
my_thread = thread_create( "
  while ( true ) {
	if ( something ) {
	  do_something();
	}
	variable += 0.1;
  }
", 0 );
```

But you must keep in mind that, the code is executed asynchronously to room_speed, so execution will cause more CPU usage. Sometimes you will need to delay loop with `sleep()` function:


```
my_thread = thread_create( "
  while ( true ) {
	if ( something ) {
	  do_something();
	}
	variable += 0.1;
	sleep( 1000 ); // wait second
  }
", 0 );
```

Terminating thread:
You can terminate a thread with thread_terminate function, but use it only if you really have to terminate a thread, because when it is terminated with this function GM is unable to free used resources/memory, causing memory leaks. To terminate an thread safely, You should use statements:
```
my_thread = thread_create( "
  while (!global.terminated) { // execute until thread is about to terminate
	do_something();
	do_something();
	do_something();
	if ( global.terminated )
    exit; // terminate on this line when thread is about to terminate
	do_something();
	do_something();
  }
", 0 );
```
and all you have to do is set global.terminated variable to true.

Note:
Threads are running even when room changes, so you have to check for existance of objects or variables. When an error occurs in GML code (syntax error, unknown variable or object etc.) - thread will be terminated without showing you any error messages. You can also use an comments in code :P

# Known bugs:
- In threads, messages such as "show_message" cannot be closed.
- In threads, all opened windows (like get_open_filename) are not blocking main game window.
