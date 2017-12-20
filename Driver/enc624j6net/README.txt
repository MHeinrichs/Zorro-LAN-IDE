ENC624J6net

SANA-II Driver for Matze/Scrat ZII IDE LAN CP card

author: Henryk Richter <henryk.richter@gmx.net>




Installation:
-------------

The driver (enc624j6net.device) needs to be copied into Devs:Networks. The configuration
depends on the TCP/IP stack of choice. Please refer to the respective documentation
how to configure a network interface.

Use the supplied GUI for stacks like Genesis or Miami and add a regular ethernet card 
within those by referring to the enc624j6net.device, unit 0.

The recent RoadShow stack is commandline-based. Please add a new file in devs:NetInterfaces,
such as a copy of the PlipBox interface specification with the device entry replaced by
enc624j6net.device. The command AddNetInterface with the filename of your interface spec
as argument will then activate the driver for RoadShow. 


Technical notes:
----------------

Matze's card does selective byte swapping for different areas of the chip within
the CPLD. This step enables Big Endian reads/writes to the hardware registers. Since
the SRAM would be byte-swapped as well, the latest (WIP) version of the CPLD presents
TX and RX frames in Big Endian (network order) as well. As a consequence, the
low-level part of the driver won't work out of the box with with other approaches 
towards 16 Bit parallel connections of the ENC624J600 chip.


Copyrights and Acknowledgements:
--------------------------------

My deepest respects go to Christian Vogelgsang (lafalla) for his plipbox project.
His invaluable work on further cleanups and abstractions to the already well written
magPLIP made a quick swap of low-level functions quite easily possible.

The ENC624J6 source is heavily based on plipbox, which is in turn based on the magPLIP
driver found on aminet.net:

http://lallafa.de/blog/amiga-projects/plipbox/
http://aminet.net/package/comm/net/magPLIP38.1

magPLIP - SANA II compliant PLIP device driver for AmiTCP/IP, Envoy,
            AS225 and other networking packages

  (C) Copyright 1993-1994 Oliver Wagner, Michael Balzer
  (C) Copyright 1995 Jan Kratochvil & Martin Mares
  (C) Copyright 1995-1996 Marius Groeger
      All Rights Reserved.

  Changes have been made by Stéphane Zermatten to the driver to connect
  a LinuxBox to an Amiga via a LapLing cable, based on the release 37.8.
