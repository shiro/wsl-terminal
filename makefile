#############################################################################
# build a wsltty installer package:
# configure ver=... and minttyver= in this makefile
# make targets:
# make [all]	build a distributable installer (default)
# make pkg	build an installer, bypassing the system checks
# make wsltty	build the software, using the local copy of mintty


# term release
ver=3.0.6


# mintty release version
minttyver=3.0.6

# wslbridge release version
wslbridgever=0.4

##############################

# mintty branch or commit version
#minttyver=master

#############################################################################
# default target

all:	all-$(notdir $(CURDIR))

all-term:	check pkg

#############################################################################
# target checking and some defs

TARGET := $(shell $(CC) -dumpmachine)

ifeq ($(TARGET), i686-pc-cygwin)
  sys := cygwin32
else ifeq ($(TARGET), x86_64-pc-cygwin)
  sys := cygwin64
else ifeq ($(TARGET), i686-pc-msys)
  sys := msys32
else ifeq ($(TARGET), x86_64-pc-msys)
  sys := msys64
else
  $(error Target '$(TARGET)' not supported)
endif

wget=curl -R -L --connect-timeout 55 -O
wgeto=curl -R -L --connect-timeout 55

#############################################################################
# system check:
# - ensure the path name drag-and-drop adaptation works (-> Cygwin, not MSYS)
# - 64 Bit (x86_64) for more stable invocation (avoid fork issues)

check:
	# checking suitable host environment; run `make pkg` to bypass
	# check cygwin (vs msys) for proper drag-and-drop paths:
	uname | grep CYGWIN
	# check 32 bit to ensure 32-Bit Windows support, just in case:
	#uname -m | grep i686
	# check 64 bit to provide 64-Bit stability support:
	uname -m | grep x86_64

#############################################################################
# generation

wslbridge:	wslbridge-source
	mkdir -p bin
	cp wslbridge2-$(wslbridgever)/wslbridge2-backend bin/
	cp wslbridge2-$(wslbridgever)/hvpty-backend bin/
	cp wslbridge2-$(wslbridgever)/wslbridge2.exe bin/
	cp wslbridge2-$(wslbridgever)/hvpty.exe bin/
	rm -rf wslbridge2-$(wslbridgever)-compiled.7z wslbridge2-$(wslbridgever)


wslbridge-source:
	echo ------------- Downloading wslbridge2 backend
	$(wgeto) https://github.com/Biswa96/wslbridge2/releases/download/v$(wslbridgever)/wslbridge2_cygwin_x86_64.7z \
	  -o wslbridge2-$(wslbridgever)-compiled.7z
	7z x -y wslbridge2-$(wslbridgever)-compiled.7z \
    -owslbridge2-$(wslbridgever)

mintty-get:
	mkdir -p build
	$(wgeto) https://github.com/mintty/mintty/archive/$(minttyver).zip -o build/mintty-$(minttyver).zip
	unzip -d build -o build/mintty-$(minttyver).zip
	cp build/mintty-$(minttyver)/icon/terminal.ico build/mintty.ico

wslbuild=LDFLAGS="-static -static-libgcc -s"
wslversion=VERSION_SUFFIX="– term $(ver)" WSLTTY_VERSION="$(ver)"

mintty-build:
	# ensure rebuild of version-specific check and message
	rm -f build/mintty-$(minttyver)/bin/*/windialog.o
	# build mintty
	cd build/mintty-$(minttyver)/src; make $(wslbuild) $(wslversion)
	mkdir -p bin
	cp build/mintty-$(minttyver)/bin/mintty.exe bin/
	strip bin/mintty.exe

mintty-pkg:
	cp build/mintty-$(minttyver)/LICENSE LICENSE.mintty
	cd build/mintty-$(minttyver)/lang; zoo a lang *.po; mv lang.zoo ../../
	cd build/mintty-$(minttyver)/themes; zoo a themes *[!~]; mv themes.zoo ../../
	cd build/mintty-$(minttyver)/sounds; zoo a sounds *.wav *.WAV *.md; mv sounds.zoo ../../
	# add charnames.txt to support "Character Info"
	cd build/mintty-$(minttyver)/src; sh ./mknames
	cp build/mintty-$(minttyver)/src/charnames.txt build/

cygwin:	# mkshortcutexe
	mkdir -p bin
	cp /bin/cygwin1.dll bin/
	cp /bin/cygwin-console-helper.exe bin/
	cp /bin/dash.exe bin/
	cp /bin/regtool.exe bin/
	cp /bin/zoo.exe bin/

mkshortcutexe:	bin/mkshortcut.exe

bin/mkshortcut.exe:	mkshortcut.c
	echo mksh
	gcc -o bin/mkshortcut mkshortcut.c -lpopt -lole32 /usr/lib/w32api/libuuid.a
	cp /bin/cygpopt-0.dll bin/
	cp /bin/cygiconv-2.dll bin/
	cp /bin/cygintl-8.dll bin/

cop:	ver
	mkdir -p release
	rm -fr release/wsltty-$(ver)-install.exe
	sed -e "s,%version%,$(ver)," makewinx.cfg > release/wsltty.SED
	cp bin/cygwin1.dll release/
	cp bin/cygwin-console-helper.exe release/
	cp bin/dash.exe release/
	cp bin/regtool.exe release/
	cp bin/mintty.exe release/
	cp bin/wsl.exe release/
	cp bin/zoo.exe release/
	cp build/lang.zoo release/
	cp build/themes.zoo release/
	cp build/sounds.zoo release/
	cp build/charnames.txt release/
	cp build/mintty.ico release/
	cp bin/wslbridge2.exe release/
	cp bin/wslbridge2-backend release/
	cp bin/hvpty.exe release/
	cp bin/hvpty-backend release/
	cp mkshortcut.vbs release/
	cp LICENSE.* release/
	cp VERSION release/
	cp *.lnk release/
	cp *.ico release/
	cp *.url release/
	cp *.bat release/
	cp *.sh release/
	cp *.vbs release/

cab:	cop
	cd release; iexpress /n wsltty.SED

install:	cop installbat

installbat:
	cd release; cmd /C install

ahk-get:
	mkdir -p build
	$(wgeto) https://autohotkey.com/download/ahk.zip \
		-o build/ahk.zip
	unzip -o -d build/ahk build/ahk.zip

ahk-build:
	chmod 777 -R build/ahk
	build/ahk/Compiler/Ahk2Exe.exe /in open-wsl.ahk /out bin/wsl.exe /icon icons/terminal.ico

ahk: ahk-get ahk-build

ver:
	echo $(ver) > VERSION

mintty:	mintty-get mintty-build

# local wsltty build target:
term:	wslbridge cygwin ahk mintty-build mintty-pkg

# standalone wsltty package build target:
pkg:	wslbridge cygwin mintty-get mintty-build mintty-pkg cab


#############################################################################
# end
