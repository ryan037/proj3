
#include <iostream>
#include <string>
#include "gen.h"
#include "symtab.h"

using namespace std;

Generator::Generator()
{}
void Generator::print_t()
{
   for(int i = in_block; i>0; i-- ){
      cout << "\t";
      file << "\t";
   }
}
void Generator::expression_handle(Node* data, string class_name)
{
   string output = "";                   
   
   if(data->geteType() == Constant){ // constant Val
      if(data->getvType() == type_integer){
         output += "sipush ";
         output += to_string(data->getValue());
      }                        
      else if(data->getvType() == type_bool){
         if(data->getValue() == 1)
            output += "iconst_1";      
         else
            output += "iconst_0";      
      }else if(data->getvType() == type_string){
         output +="ldc ";
         output += data->getValue_string();
      }
      output += "\n";
   }                        
   else{                  //variable
      if(data->getScope() == "global"){ //global
         output += "getstatic ";                                                        if(data->getvType() == type_integer) //
	 {
   	    output += "int ";
	 }else if(data->getvType() == type_bool){ //bool
            output += "bool ";
         }
            output += class_name;
            output += ".";
            output += data->getIdentifier();
         }else if(data->getScope() == "local"){ //local
            output += "iload ";
            output += to_string(data->getNum());
         }
         output += "\n";       
    }
    if(output != "")
         this->identifier(output);
}

void Generator::beginProgram(string s)
{ 
   file << "class " << s << "{" << endl; 
   cout << "class " << s << endl;
   cout << "{" << endl;
}
void Generator::closeProgram()
{
   file << "}" << endl; 
   cout << '}' << endl;
}

void Generator::beginFun(Node* data)
{
   print_t();
   cout << "method public static " << vEnumToString(data->getvType()) << " " << data->getIdentifier() << '(';
   file << "method public static " << vEnumToString(data->getvType()) << " " << data->getIdentifier() << '(';
   if(data->getIdentifier() == "main"){
     cout << "java.lang.String[])\n";
     file << "java.lang.String[])\n";
   }
   else if(data->func_para.size() == 1){
      cout << vEnumToString(data->func_para[0]) << ')' << endl;
      file << vEnumToString(data->func_para[0]) << ')' << endl;
   }
   else if(data->func_para.size() > 1){
      int i=0;
      for(i=0; i<data->func_para.size()-1; i++){
         cout << vEnumToString(data->func_para[i]) << ", ";
         file << vEnumToString(data->func_para[i]) << ", ";
      }
      cout << vEnumToString(data->func_para[i]) << ')' << endl;
      file << vEnumToString(data->func_para[i]) << ')' << endl;
   }else{
      cout << ")" << endl; 
      file << ")" << endl; 
   }
   //-----------------------------------------------------

   print_t();
   cout << "max_stack 15" << endl; 
   file << "max_stack 15" << endl; 
   
   print_t();
   cout  << "{" << endl;
   file << "{" << endl;

   //-----------------------------------------------------
   
   for(int i=0; i<data->func_para.size(); i++){
          print_t();
          print_t();
          cout << "iload " << i << endl;
          file << "iload " << i << endl;
   }
}
void Generator::returnValue(ValueType v)
{
   if(v == type_integer){
      print_t();
      cout << "ireturn" << endl;
      file << "ireturn" << endl;
      in_block-=1;
      print_t();
      cout << "}" << endl;
      file << "}" << endl;
      in_block+=1;
   }
   else if(v == type_void){
      print_t();
      cout << "return"; 
      file << "return";
      print_t();
      cout << endl; 
      file<< endl;
      in_block-=1;
      print_t();
      cout<< "}" << endl;
      file << "}" << endl;
      in_block+=1;
   }
}
void Generator::globalVarValue(Node* data)
{
   print_t();
   file << "field static " << "int "  << data->getIdentifier() << " = "  << data->getValue() << endl;
   cout << "field static " << "int "  << data->getIdentifier() << " = "  << data->getValue() << endl;
}
void Generator::globalVar(Node* data)
{
   print_t();
   cout << "field static " <<  "int " << data->getIdentifier() << endl;
   file << "field static " <<  "int " << data->getIdentifier() << endl;
}
void Generator::localVarValue(Node* data)
{
   print_t();
   cout << "sipush " << data->getValue() << endl;
   file << "sipush " << data->getValue() << endl;
   print_t();
   cout << "istore " << data->getNum() << endl;
   file << "istore " << data->getNum() << endl;
}
void Generator::identifier(string s)
{
   print_t();
   cout << s;
   file << s;
}
void Generator::assign(string s)
{
   print_t();
   cout << s;
   file << s;
}
void Generator::printStart()
{
   print_t();
   file << "getstatic java.io.PrintStream java.lang.System.out\n";
   cout << "getstatic java.io.PrintStream java.lang.System.out\n";
}
void Generator::printOutput(ValueType v)
{
   if(v == type_string){
    print_t();
    file << "invokevirtual void java.io.PrintStream.print(java.lang.String)\n";
    cout << "invokevirtual void java.io.PrintStream.print(java.lang.String)\n";
   }
   if(v == type_integer){
    print_t();
    file << "invokevirtual void java.io.PrintStream.print(int)\n";
    cout << "invokevirtual void java.io.PrintStream.print(int)\n";
   }
   if(v == type_bool){
    print_t();
    file << "invokevirtual void java.io.PrintStream.print(boolean)\n";
    cout << "invokevirtual void java.io.PrintStream.print(boolean)\n";
   }
}
void Generator::printlnOutput(ValueType v)
{
   if(v == type_string){
    print_t();
    file << "invokevirtual void java.io.PrintStream.println(java.lang.String)\n";
    cout << "invokevirtual void java.io.PrintStream.println(java.lang.String)\n";
   }
   if(v == type_integer){
    print_t();
    file << "invokevirtual void java.io.PrintStream.println(int)\n";
    cout << "invokevirtual void java.io.PrintStream.println(int)\n";
   }
   if(v == type_bool){
    print_t();
    file << "invokevirtual void java.io.PrintStream.println(boolean)\n";
    cout << "invokevirtual void java.io.PrintStream.println(boolean)\n";
   }
}
void Generator::beginif(int i)
{
  cout << " L" << i << endl;
  file << " L" << i << endl;
  print_t();
  cout << "iconst_0" << endl;
  file << "iconst_0" << endl;
  print_t();
  cout << "goto L" << i+1 << endl;
  file << "goto L" << i+1 << endl;
  cout << "L" << i << ":\n";
  file << "L" << i << ":\n";
  print_t();
  cout << "iconst_1" << endl;
  file << "iconst_1" << endl;
  cout  << "L" << i+1 << ":\n";
  file  << "L" << i+1 << ":\n";
  print_t();
  cout <<"ifeq L" << i+2 << endl;  
  file <<"ifeq L" << i+2 << endl;  
}
void Generator::beginelse(int i)
{
   print_t();
   cout << "goto L" << i+1 << endl;
   file << "goto L" << i+1 << endl;
   print_t();
   cout<< "L" << i << ":\n";
   file<< "L" << i << ":\n";
}

void Generator::closeif(int i)
{
   cout << "L" << i << ":\n";
   file << "L" << i << ":\n";
}
void Generator::negativeIint(string s)
{
   print_t();
   cout << s;
   file << s;
}
void Generator::callFun(string s, Node* data)
{
   print_t();
   cout << "invokestatic " << vEnumToString(data->getvType()) << " " << s << "." << data->getIdentifier() << "(";
   file << "invokestatic " << vEnumToString(data->getvType()) << " " << s << "." << data->getIdentifier() << "(";

   if(data->func_para.size() == 1){
      cout << vEnumToString(data->func_para[0]) << ')' << endl;
      file << vEnumToString(data->func_para[0]) << ')' << endl;
   }
   else if(data->func_para.size() > 1){
      int i=0;
      for(i=0; i<data->func_para.size()-1; i++){
         cout << vEnumToString(data->func_para[i]) << ", ";
         file << vEnumToString(data->func_para[i]) << ", ";
      }
      cout <<vEnumToString(data->func_para[i]) << ')' << endl;
      file <<vEnumToString(data->func_para[i]) << ')' << endl;
   }else{
      cout << ")" << endl; 
      file << ")" << endl; 
   }
}
void Generator::operation(string s)
{
   print_t();
   cout << s;
   file << s;
}
void Generator::beginWhile(int i)
{
   cout << "L" << i << ":\n";
   file << "L" << i << ":\n";
}
void Generator::insideWhile(int i)
{
   cout << " L" << i << endl;
   file << " L" << i << endl;
   print_t();
   cout << "iconst_0\n";
   file << "iconst_0\n";
   print_t();
   cout << "goto L" << i+1 << endl;
   file << "goto L" << i+1 << endl;
  
   cout << "L" << i << ":\n";
   file << "L" << i << ":\n";
   print_t();
   cout << "iconst_1\n";
   file << "iconst_1\n";
   
   cout << "L" << i+1 << ":\n";
   file << "L" << i+1 << ":\n";
   print_t();
   cout << "ifeq L" << i+2 << endl;  
   file << "ifeq L" << i+2 << endl;  
}
void Generator::closeWhile(int i)
{
   print_t();
   cout << "goto L" << i-3 << endl;
   file << "goto L" << i-3 << endl;
   
   cout << "L" << i << ":\n";
   file << "L" << i << ":\n";
}
void Generator::beginFor(string s ,int i)
{
   print_t();
   cout << s;
   file << s;
   cout << "L" << i << ":\n";
   file << "L" << i << ":\n";
}
void Generator::insideFor(string s ,int i)
{
   print_t();
   cout << s;
   file << s;
   cout << " L" << i << endl;
   file << " L" << i << endl;
   print_t();
   cout << "iconst_0\n";
   file << "iconst_0\n";
   print_t();
   cout << "goto L" << i+1 << endl;
   file << "goto L" << i+1 << endl;
   cout << "L" << i << ":\n";
   file << "L" << i << ":\n";
   print_t();
   cout << "iconst_1\n";
   file << "iconst_1\n";
   cout << "L" << i+1 << ":\n";
   file << "L" << i+1 << ":\n";
   print_t();
   cout << "ifeq L" << i+2 << endl;  
   file << "ifeq L" << i+2 << endl;  
}
void Generator::closeFor(string s ,int i)
{
   print_t();
   cout << s;
   file << s;
   print_t();
   cout << "goto L" << i-3 << endl;
   file << "goto L" << i-3 << endl;
   cout << "L" << i << ":\n";
   file << "L" << i << ":\n";
}
