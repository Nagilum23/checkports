Checkports
==========

Check ELF files of installed ports for missing dependencies and report packages that should be reistalled.
Works with pkgng.

Usage
=====
./checkports.pl

Example output:
<pre>~ > ./checkports.pl
Collecting ELF files [5259/179991] done.
Checking files [386] done.
neon29-0.29.6_4: => /usr/local/lib/libneon.so
mplayer-1.1.r20130308: => /usr/local/bin/mplayer
</pre>
You should then reinstall those ports since they are currently broken.
