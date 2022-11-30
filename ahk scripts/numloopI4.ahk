No := 1                               ; number to start counting from

F12::                                 ; key to start loop
Loop {
    Send,{down 10}
    Send,{backspace 2}
    Send, % No
    No++
	Send,{enter}
  Sleep, 1010                          ; how long in milliseconds before it starts sending messages again
}

F9::                                  ; key to pause looping
Suspend
Pause,, 1
Return