#!/bin/bash

if [ $1 == "setup" ] 
then
	./my_shell_injection.sh 0
else
	./my_shell_injection.sh 1 64 HT20
fi
