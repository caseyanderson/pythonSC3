import argparse
import keyboard
import pyOSC3
import random
from time import sleep

# parse command line arguments
parser = argparse.ArgumentParser()
parser.add_argument("--addr", type=str, help="the address", default="engine")
parser.add_argument("--port", type=int, help="the listener's port number", default=57120)
args = parser.parse_args()

client = pyOSC3.OSCClient()
client.connect(('127.0.0.1', args.port))

msg = pyOSC3.OSCMessage()

address = ''.join(["/", args.addr ])

msg.setAddress(str(address))

freq = random.randint(1, 12)
msg.append(freq)

keyPress = False
trigCount = 0

while True:
    if trigCount == 0 and keyboard.is_pressed('Space') and keyPress == False:
        trigCount+=1
        print(''.join(["trig count: ", str(trigCount)]))
        client.send(msg)
        keyPress = True
    elif trigCount > 0 and keyboard.is_pressed('Space') and keyPress == False:
        trigCount+=1
        print(''.join(["trig count: ", str(trigCount)]))
        msg[0] = random.randint(1, 12)
        client.send(msg)
        keyPress = True
    elif keyboard.is_pressed('Space') == False and keyPress == True:
        keyPress = False
    elif keyboard.is_pressed('q') == True:
        print("goodbye!")
        client.close()
        break
    sleep(0.001)
