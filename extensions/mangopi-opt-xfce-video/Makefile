# GStreamer plugin. Needs libgstreamer-plugins-base1.0-dev and pkg-config.
CC ?= gcc
VECFLAGS = -O2 -march=rv64gc_xtheadvector -mabi=lp64d
CFLAGS = -O2 -Wall
GSTCFLAGS = $(shell pkg-config --cflags gstreamer-video-1.0)
GSTLIBS = $(shell pkg-config --libs gstreamer-video-1.0)
libgstmangopinv12conv.so: gstmangopinv12conv.c nv12conv.c nv12conv_vec.c nv12conv.h
	$(CC) $(CFLAGS) -fPIC $(GSTCFLAGS) -c gstmangopinv12conv.c -o gst.o
	$(CC) $(CFLAGS) -fPIC -c nv12conv.c -o nv12conv.po
	$(CC) $(VECFLAGS) -fPIC -Wall -c nv12conv_vec.c -o nv12conv_vec.po
	$(CC) -shared -o $@ gst.o nv12conv.po nv12conv_vec.po $(GSTLIBS)
