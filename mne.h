#include "flags.hpp"

static void whoami(const char *name)
{
	if (flags::instructions) {
		while (*name) {
			Program.push_back(*name);
			++name;
		}
		Program.push_back('(');
	}
}

static void endwhoami()
{
	if (flags::instructions) {
		Program.push_back(')');
	}
}

#define WHOAMI whoami(__func__)
#define ENDWHOAMI endwhoami()


static void emit_S()
{
	if (flags::annotations) {
		Program.push_back('S');
	}
	Program.push_back(' ');
}

static void emit_T()
{
	if (flags::annotations) {
		Program.push_back('T');
	}
	Program.push_back('\t');
}

static void emit_L()
{
	if (flags::annotations) {
		Program.push_back('L');
	}
	Program.push_back('\n');
}

static void IMP_stack()
{
	emit_S();
}

static void IMP_math()
{
	emit_T();
	emit_S();
}

static void IMP_heap()
{
	emit_T();
	emit_T();
}

static void IMP_flow()
{
	emit_L();
}

static void IMP_io()
{
	emit_T();
	emit_L();
}

static void make_number(int value)
{
	WHOAMI;
	/* Quoted from whitespace docu:

	Numbers can be any number of bits wide, and are simply
	represented as a series of [Space] and [Tab], terminated by a [LF].
	[Space] represents the binary digit 0, [Tab] represents 1. The sign
	of a number is given by its first character, [Space] for positive
	and [Tab] for negative. Note that this is not twos complement, it
	just indicates a sign.
	*/
	
	if (value > 0) {
		emit_S();
	} else if (value < 0) {
		emit_T();
		value = - value;
	} else {
		emit_S();
		emit_S();
		emit_L();
		ENDWHOAMI;
		return;
	}
	bool leading_zero = true;
	for (int i = 31; i >= 0; --i) {
		if (value & (1 << i)) {
			leading_zero = false;
			emit_T();
		} else if (! leading_zero) {
			emit_S();
		}
	}
	emit_L();
	ENDWHOAMI;
}

static void make_label(int value)
{
	WHOAMI;
	/* Quoted from whitespace docu:

	Labels are simply [LF] terminated lists of spaces and tabs. There
	is only one global namespace so all labels must be unique.
	*/
	if (value == 0) {
		emit_S();
	}
	while (value) {
		if (value & 1) {
			emit_T();
		} else {
			emit_S();
		}
		value >>= 1;
	}
	emit_L();
	ENDWHOAMI;
}

static void mne_push(int value)
{
	WHOAMI;
	IMP_stack();
	emit_S();
	make_number(value);
	ENDWHOAMI;
}

static void mne_dup()
{
	WHOAMI;
	IMP_stack();
	emit_L();
	emit_S();
	ENDWHOAMI;
}

static void mne_swap()
{
	WHOAMI;
	IMP_stack();
	emit_L();
	emit_T();
	ENDWHOAMI;
}

static void mne_pop()
{
	WHOAMI;
	IMP_stack();
	emit_L();
	emit_L();
	ENDWHOAMI;
}

static void mne_add()
{
	WHOAMI;
	IMP_math();
	emit_S();
	emit_S();
	ENDWHOAMI;
}

static void mne_sub()
{
	WHOAMI;
	IMP_math();
	emit_S();
	emit_T();
	ENDWHOAMI;
}

static void mne_mul()
{
	WHOAMI;
	IMP_math();
	emit_S();
	emit_L();
	ENDWHOAMI;
}

static void mne_div()
{
	WHOAMI;
	IMP_math();
	emit_T();
	emit_S();
	ENDWHOAMI;
}

static void mne_mod()
{
	WHOAMI;
	IMP_math();
	emit_T();
	emit_T();
	ENDWHOAMI;
}

static void mne_store()
{
	WHOAMI;
	IMP_heap();
	emit_S();
	ENDWHOAMI;
}

static void mne_fetch()
{
	WHOAMI;
	IMP_heap();
	emit_T();
	ENDWHOAMI;
}

static void mne_label(int id)
{
	WHOAMI;
	IMP_flow();
	emit_S();
	emit_S();
	make_label(id);
	ENDWHOAMI;
}

static void mne_call(int id)
{
	WHOAMI;
	IMP_flow();
	emit_S();
	emit_T();
	make_label(id);
	ENDWHOAMI;
}

static void mne_jmp(int id)
{
	WHOAMI;
	IMP_flow();
	emit_S();
	emit_L();
	make_label(id);
	ENDWHOAMI;
}

static void mne_jz(int id)
{
	WHOAMI;
	IMP_flow();
	emit_T();
	emit_S();
	make_label(id);
	ENDWHOAMI;
}

static void mne_jneg(int id)
{
	WHOAMI;
	IMP_flow();
	emit_T();
	emit_T();
	make_label(id);
	ENDWHOAMI;
}

static void mne_ret()
{
	WHOAMI;
	IMP_flow();
	emit_T();
	emit_L();
	ENDWHOAMI;
}

static void mne_exit()
{
	WHOAMI;
	IMP_flow();
	emit_L();
	emit_L();
	ENDWHOAMI;
}

static void mne_putc()
{
	WHOAMI;
	IMP_io();
	emit_S();
	emit_S();
	ENDWHOAMI;
}

static void mne_puti()
{
	WHOAMI;
	IMP_io();
	emit_S();
	emit_T();
	ENDWHOAMI;
}

static void mne_getc()
{
	WHOAMI;
	IMP_io();
	emit_T();
	emit_S();
	ENDWHOAMI;
}

static void mne_geti()
{
	WHOAMI;
	IMP_io();
	emit_T();
	emit_T();
	ENDWHOAMI;
}




