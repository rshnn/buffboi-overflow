ASFLAGS := -m32
CFLAGS  := -m32 -g -std=c99 -Wall -Werror -D_GNU_SOURCE
LDFLAGS := -m32
LDLIBS  := -lcrypto
PROGS   := zookd \
           zookd-exstack \
           zookd-nxstack \
           zookd-withssp \
           shellcode.bin run-shellcode

ifeq ($(wildcard /usr/bin/execstack),)
  ifneq ($(wildcard /usr/sbin/execstack),)
    ifeq ($(filter /usr/sbin,$(subst :, ,$(PATH))),)
      PATH := $(PATH):/usr/sbin
    endif
  endif
endif

all: $(PROGS)
.PHONY: all

zookld zookd zookfs: %: %.o http.o
zookd-withssp: %: %.o http-withssp.o
run-shellcode: %: %.o

%-nxstack: %
	cp $< $@

%-exstack: %
	cp $< $@
	execstack -s $@

%.o: %.c
	$(CC) $< -c -o $@ $(CFLAGS) -fno-stack-protector

%-withssp.o: %.c
	$(CC) $< -c -o $@ $(CFLAGS)

%.bin: %.o
	objcopy -S -O binary -j .text $< $@


# For staff use only
staff-bin: zookd zookd-exstack zookd-nxstack
	tar cvzf bin.tar.gz $^

.PHONY: check-libc
check-libc: bin.tar.gz exploit-libc1.py exploit-libc2.py
	./check-ldcache.sh
	tar xf bin.tar.gz
	./check-part3.sh zookd-nxstack ./exploit-libc1.py
	./check-part3.sh zookd-nxstack ./exploit-libc2.py

.PHONY: check-libc-fixed
check-libc-fixed: clean $(PROGS) exploit-libc1.py exploit-libc2.py
	./check-part3.sh zookd-nxstack ./exploit-libc1.py
	./check-part3.sh zookd-nxstack ./exploit-libc2.py

.PHONY: check-zoobar
check-zoobar:
	./check_zoobar.py

.PHONY: check
check: check-zoobar check-libc


.PHONY: fix-flask
fix-flask: fix-flask.sh
	./fix-flask.sh

.PHONY: clean
clean:
	rm -f *.o *.pyc *.bin $(PROGS)

.PHONY: check-version
check-version:
	$(info This Makefile is for assignment 2)
	@:


assignment%-handin.tar.gz: clean
	tar cf - `find . -type f | grep -v '^\.*$$' | grep -v '/CVS/' | grep -v '/\.svn/' | grep -v '/\.git/' | grep -v 'assignment[0-9].*\.tar\.gz' | grep -v '/submit.token$$' | grep -v libz3str.so` | gzip > $@

.PHONY: prepare-submit
prepare-submit: assignment2-handin.tar.gz

.PRECIOUS: assignment2-handin.tar.gz
