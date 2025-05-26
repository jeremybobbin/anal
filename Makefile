.POSIX:
.PHONY: test


.y.c:
	$(YACC) $(YFLAGS) $< -o $@

CC=cc

anal: l.o y.o
	$(CC) -o $@ $<

y.c: y.y

l.o: y.c

clean:
	rm -f anal l.c l.o y.c y.o

test: anal
	./anal < t/main.c
