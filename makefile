#############################################################################
# build a wsltty installer package:
# configure ver=... and minttyver= in this makefile
# make targets:
# make [all]	build a distributable installer (default)
# make pkg	build an installer, bypassing the system checks
# make wsltty	build the software, using the local copy of mintty


# wsltty release
ver=3.0.6

# wsltty appx release - must have 4 parts!
verx=3.0.6.0

# mintty release version
minttyver=3.0.6

# wslbridge release version
wslbridgever=0.4

##############################

# mintty branch or commit version
#minttyver=master

##############################
# Windows SDK version for appx
WINSDKKEY=/HKEY_LOCAL_MACHINE/SOFTWARE/WOW6432Node/Microsoft/.NET Framework Platform/Setup/Multi-Targeting Pack
WINSDKVER=`regtool list '$(WINSDKKEY)' | sed -e '$$ q' -e d`

#############################################################################
# default target

all:	all-$(notdir $(CURDIR))

all-wsltty:	check pkg

all-wsltty.appx:	appx

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
# patch version information for appx package configuration

fix-verx:
	echo patching $(WINSDKVER) into Launcher config
	cd Launcher; sed -i~ -e "/<supportedRuntime / s,Version=v[.0-9]*,Version=$(WINSDKVER)," app.config
	echo patched app.config
	cd Launcher; sed -i~ -e "/<TargetFrameworkVersion>/ s,v[.0-9]*,$(WINSDKVER)," Launcher.csproj
	echo patched Launcher.csproj
	echo patching $(verx) into app config
	sed -i~ -e '/<Identity / s,Version="[.0-9]*",Version="$(verx)",' AppxManifest.xml
	echo patched AppxManifest.xml

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
	$(wgeto) https://github.com/mintty/mintty/archive/$(minttyver).zip -o mintty-$(minttyver).zip
	unzip -o mintty-$(minttyver).zip
	cp mintty-$(minttyver)/icon/terminal.ico mintty.ico

wslbuild=LDFLAGS="-static -static-libgcc -s"
appxbuild=$(wslbuild) CCOPT=-DWSLTTY_APPX
wslversion=VERSION_SUFFIX="– wsltty $(ver)" WSLTTY_VERSION="$(ver)"
appxversion=VERSION_SUFFIX="– wsltty appx $(verx)" WSLTTY_VERSION="$(verx)"

mintty-build:
	# ensure rebuild of version-specific check and message
	rm -f mintty-$(minttyver)/bin/*/windialog.o
	# build mintty
	cd mintty-$(minttyver)/src; make $(wslbuild) $(wslversion)
	mkdir -p bin
	cp mintty-$(minttyver)/bin/mintty.exe bin/
	strip bin/mintty.exe

mintty-build-appx:
	# ensure rebuild of version-specific check and message
	rm -f mintty-$(minttyver)/bin/*/windialog.o
	# build mintty
	cd mintty-$(minttyver)/src; make $(appxbuild) $(appxversion)
	mkdir -p bin
	cp mintty-$(minttyver)/bin/mintty.exe bin/
	strip bin/mintty.exe

mintty-pkg:
	cp mintty-$(minttyver)/LICENSE LICENSE.mintty
	cd mintty-$(minttyver)/lang; zoo a lang *.po; mv lang.zoo ../../
	cd mintty-$(minttyver)/themes; zoo a themes *[!~]; mv themes.zoo ../../
	cd mintty-$(minttyver)/sounds; zoo a sounds *.wav *.WAV *.md; mv sounds.zoo ../../
	# add charnames.txt to support "Character Info"
	cd mintty-$(minttyver)/src; sh ./mknames
	cp mintty-$(minttyver)/src/charnames.txt .

mintty-appx:
	mkdir -p usr/share/mintty
	cd usr/share/mintty; mkdir -p lang themes sounds info
	cp mintty-$(minttyver)/lang/*.po usr/share/mintty/lang/
	cp mintty-$(minttyver)/themes/*[!~] usr/share/mintty/themes/
	cp mintty-$(minttyver)/sounds/*.wav usr/share/mintty/sounds/
	cp mintty-$(minttyver)/sounds/*.WAV usr/share/mintty/sounds/
	# add charnames.txt to support "Character Info"
	cd mintty-$(minttyver)/src; sh ./mknames
	cp mintty-$(minttyver)/src/charnames.txt usr/share/mintty/info/

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

appx-bin:
	mkdir -p bin
	cp /bin/cygwin1.dll bin/
	cp /bin/cygwin-console-helper.exe bin/

cop:	ver
	mkdir -p rel
	rm -fr rel/wsltty-$(ver)-install.exe
	sed -e "s,%version%,$(ver)," makewinx.cfg > rel/wsltty.SED
	cp bin/cygwin1.dll rel/
	cp bin/cygwin-console-helper.exe rel/
	cp bin/dash.exe rel/
	cp bin/regtool.exe rel/
	cp bin/mintty.exe rel/
	cp bin/zoo.exe rel/
	cp lang.zoo rel/
	cp themes.zoo rel/
	cp sounds.zoo rel/
	cp charnames.txt rel/
	cp bin/wslbridge2.exe rel/
	cp bin/wslbridge2-backend rel/
	cp bin/hvpty.exe rel/
	cp bin/hvpty-backend rel/
	cp mkshortcut.vbs rel/
	#cp bin/mkshortcut.exe rel/
	#cp bin/cygpopt-0.dll rel/
	#cp bin/cygiconv-2.dll rel/
	#cp bin/cygintl-8.dll rel/
	cp LICENSE.* rel/
	cp VERSION rel/
	cp *.lnk rel/
	cp *.ico rel/
	cp *.url rel/
	cp *.bat rel/
	cp *.sh rel/
	cp *.vbs rel/

cab:	cop
	cd rel; iexpress /n wsltty.SED

install:	cop installbat

installbat:
	cd rel; cmd /C install

ver:
	echo $(ver) > VERSION

mintty:	mintty-get mintty-build

mintty-usr:	mintty-get mintty-appx

# local wsltty build target:
wsltty:	wslbridge cygwin mintty-build mintty-pkg

# standalone wsltty package build target:
pkg:	wslbridge cygwin mintty-get mintty-build mintty-pkg cab

# appx package contents target:
wsltty-appx:	wslbridge appx-bin mintty-get mintty-build-appx mintty-appx

# appx package target:
appx:	wsltty-appx fix-verx
	sh ./build.sh

#############################################################################
# end
