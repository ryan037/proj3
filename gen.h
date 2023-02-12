#include <stdio.h>
#include <fstream>
#include <iostream>
#include <string>
#include "symtab.h"
using namespace std;

class Generator{
public:
   Generator();
   fstream file;
   int in_block = 1;

   void print_t();
   void expression_handle(Node* data, string class_name);

   void beginProgram(string s);
   void closeProgram();
   void beginFun(Node* data);
   void returnValue(ValueType v);
   void globalVarValue(Node* data);
   void globalVar(Node* data);
   void localVarValue(Node* data);
   void identifier(string s);
   void assign(string s);
   void printStart();
   void printOutput(ValueType v);
   void printlnOutput(ValueType v);
   void beginif(int i);
   void beginelse(int i);
   void closeif(int i);
   void relationalOperator(string s);
   void negativeIint(string s);
   void callFun(string s, Node* data);
   void operation(string s);

   void beginWhile(int i);
   void insideWhile(int i);
   void closeWhile(int i);

   void beginFor(string s ,int i);
   void insideFor(string s ,int i);
   void closeFor(string s ,int i);
};
