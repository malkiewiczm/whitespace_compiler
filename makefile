MAKEFLAGS += Rr
CXX := g++
CXXFLAGS := -Wall -Wextra -Wpedantic -Wshadow -std=c++11
CXXFLAGS_LEX := -Wno-switch -std=gnu++11
LEXOUTPUT := lex.yy.c parser.tab.c parser.tab.h
LEXOBJECTS := lex.yy.o parser.tab.o

.PHONY: all

all: compile

compile: main.o $(LEXOBJECTS)
	$(CXX) $^ -o $@

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $< -c -o $@

lex.yy.o: $(LEXOUTPUT)
	$(CXX) $(CXXFLAGS_LEX) lex.yy.c -c -o $@

parser.tab.o: $(LEXOUTPUT)
	$(CXX) $(CXXFLAGS_LEX) parser.tab.c -c -o $@

lex.yy.c: lexer.l
	flex $<

parser.tab.c: parser.y mne.h
	bison -d $<

parser.tab.h: parser.tab.c
main.cpp: parser.tab.h