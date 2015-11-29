# About this project
IBM P8 functional simulator(systemsim) is a full system simulator, it don't support AIX, but according someone's work [1], AIX kernel DO boot on systeimsim. for systemsim only support bogus net and bogus disk, aix failed to boot with error UNKNOWN BOOTDEV or UNKNOWN BOOTDISK. 

Since aix 7.1 with patch IZ99822[2], tap pesudo device is added, it looks **possible** to create a simple program to bridge the tap device and systemsim bogus net device. 

[1] http://pastebin.com/kvNEvxZP
[2] http://www-01.ibm.com/support/docview.wss?uid=isg1IZ99822
