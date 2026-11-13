ifeq ($(CXX),g++)
    EXTRA_FLAGS = --no-gnu-unique
else
    EXTRA_FLAGS =
endif

CXXFLAGS ?= -O2
CXXFLAGS += -shared -fPIC -std=c++2b
SRC = main.cpp SnowCap.cpp SnowCapPass.cpp

all: snowcaps.so

snowcaps.so: $(SRC) $(wildcard *.hpp)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(EXTRA_FLAGS) $(SRC) -o snowcaps.so `pkg-config --cflags pixman-1 libdrm hyprland pangocairo libinput libudev wayland-server xkbcommon` `pkg-config --libs cairo`

clean:
	rm -f ./snowcaps.so

.PHONY: all clean
