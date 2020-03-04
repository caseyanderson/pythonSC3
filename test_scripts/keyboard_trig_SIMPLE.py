import keyboard  # using module keyboard
from time import sleep

keyPress = False
trigCount = 0

while True:
    if keyboard.is_pressed('Space') and keyPress == False:
        keyPress = True
    elif keyboard.is_pressed('Space') == False and keyPress == True:
        trigCount+=1
        print(''.join(["send trigger", "\n", "trig count: ", str(trigCount)]))
        keyPress = False
    elif keyboard.is_pressed('q') == True:
        print("goodbye!")
        break
    sleep(0.001)
