# KVM-Thought-Tor
## How to set VM to work via tor interface(example)
```
$ virt-manager 
```
# Add interface
```
  virsh attach-interface guest --type bridge --source NameOfInterface(tornet) --mac MacOfSource(00:16:3e:1b:f7:47) --config
  virsh attach-interface guest --type bridge --source tornet --mac 00:32:32:32:32:32 --config
```
### OR:
- please open properties of connections and add interface : ![Open Propetry of connections](https://pp.userapi.com/c845219/v845219600/dacc/niJvwcSyLz4.jpg)
- ![adding](https://sun9-5.userapi.com/c824200/v824200600/f0fb5/HzGdxUltDoI.jpg) Type of bridge. Onboot. 

# Set VM to interface
- On install:
  - add your VM! And set it to tornet ![Add your VM](https://sun9-7.userapi.com/c824410/v824410600/f5baf/OLtJCvysVV8.jpg)
  - ![set to bridge](https://pp.userapi.com/c846417/v846417600/99d4/jKBlq1MTqg4.jpg)
  - ![manualy network](https://sun9-3.userapi.com/c824410/v824410600/f5bea/fVk29-m0_xc.jpg)
  - ![Set IP](https://sun9-1.userapi.com/c824410/v824410600/f5bf3/efu5uqIu1tc.jpg)
  - ![Set Mask](https://sun9-6.userapi.com/c824410/v824410600/f5bfc/Z-wFgNon86I.jpg)
  - ![Set gateway](https://sun9-1.userapi.com/c824410/v824410600/f5c05/2kfV6oXaqP8.jpg)
- manually to /etc/network/interface:
```
iface tornet inet static
  address 10.100.100.125
  netmask 255.255.255.0
  gateway 10.100.100.1
```
