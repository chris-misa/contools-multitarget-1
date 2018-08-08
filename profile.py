"""Construct a profile with just one bare-metal host

Instructions:
  Wait for the profile to start,
  run $ sudo ./setup.sh on node,
  do other cool stuff. . .
"""

# Boiler plate
import geni.portal as portal
import geni.rspec.pg as rspec
request = portal.context.makeRequestRSpec()

# Get nodes
node = request.RawPC("node")
node.hardware_type="m510"

# Set scripts from repo
# node1.addService(rspec.Execute(shell="sh", command="/local/repository/initDocker.sh"))

# Boiler plate
portal.context.printRequestRSpec()
