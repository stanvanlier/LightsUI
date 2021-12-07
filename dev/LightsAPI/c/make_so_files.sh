gcc -fPIC -shared rf_sender.c -o rf_sender.so
gcc -fPIC -shared screen_backlight.c -o screen_backlight.so

gcc -fPIC -shared rf_receiver.c -o rf_receiver.so
