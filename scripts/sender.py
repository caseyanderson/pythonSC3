import pyOSC3
import argparse

# parse command line arguments
parser = argparse.ArgumentParser()
parser.add_argument("--freq", type=float, help="the frequency", default=200.0)
parser.add_argument("--addr", type=str, help="the address", default="engine")
parser.add_argument("--port", type=int, help="the listener's port number", default=57120)
args = parser.parse_args()

# create OSCClient
client = pyOSC3.OSCClient()
client.connect(('127.0.0.1', args.port))

# adding the address
msg = pyOSC3.OSCMessage()
address = ''.join(["/", str(args.addr)])

# constructing the message
msg.setAddress(str(address))
msg.append(args.freq)

# sending the message to SC
client.send(msg)