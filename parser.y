/*
%{..}%裡的東西只會include到y.tab.c, y.tab.h則沒有,所以union裡無法使用string
*/
%{
#define Trace(t)        printf(t)
#include <cstdio>
#include <iostream>
#include <typeinfo>
#include <string.h>
#include "symtab.h"
#include "gen.h"

extern FILE *yyin;
extern char *yytext;

extern int yylex(void);
static void  yyerror(const char *msg);
Symtab_list symtab_list = Symtab_list();
Generator gen;

int if_else = 0;
bool global_flag = true;
bool operation_flag = false;
int in_if_else_cout = 0;
int count = 0;
int L_count = 0;
string class_name;
//----------------------------------------- new add
vector<Node*> var_vector; 
vector<Node*> var_assign_vector;

vector<Node*> para_vector;
vector<ValueType> argu_vector;
ValueType ret_type = type_void;
//-----------------------------------------
vector<ValueType> vt;
vector<ValueType> vt2;
%}

%code requires{
   #include<string>
   #include "symtab.h"
}

%union{
	int int_dataType;
	double double_dataType;
	bool bool_dataType;
	char* string_dataType;
        Node* compound_dataType;
        ValueType dataType;
}



/* tokens */
%token ADD ADDEQ SUB SUBEQ MULEQ DIVEQ EQ NEQ LEQ GEQ AND OR
%token SEMI SEMICOLON DD
%token BOOL BREAK CHAR CASE CONST CONTINUE DO DOUBLE DEFAULT ELSE EXTERN FLOAT FOR FOREACH IF INT PRINT PRINTLN READ RETURN STRING SWITCH VOID WHILE
%type expression
%type<dataType> data_type
%type<dataType> function_variation

%token <int_dataType> INT_CONST
%token <double_dataType> REAL_CONST
%token <bool_dataType> BOOL_CONST
%token <string_dataType> STR_CONST
%token <string_dataType> ID


%type <compound_dataType> identifier_list constant_values expression call_function logical_expression relational_expression bool_expression calculation_expression variable_choice constant_choice print_choice no_semi_statement no_semi_assign no_semi_ADD_SUB



	          
%left OR
%left AND
%left '!'
%left '<' LEQ EQ GEQ '>' NEQ
%left ADD '+' SUB '-'
%left '*' '/'
%nonassoc UMINUS



%%
program:        program function_choice
                {
		} 
              | program variable_choice 
		{
		}
              | program constant_choice
		{
		}
              | {
                };
                                

function_choice:   data_type ID
	           {
			global_flag = false;	
			Node *data = new Node($2, Function, $1);
			symtab_list.insert_token(data);
			symtab_list.push();
                   }
	           function_variation
                   {
			Node *data = symtab_list.lookup_token($2);
			for(int i=0; i<para_vector.size(); i++){
				data->func_para.push_back(para_vector[i]->getvType());
				symtab_list.insert_token(para_vector[i]);
			}
			gen.beginFun(data);
			gen.in_block += 1;
			para_vector.clear();
                   }
                   '{' inside_function '}'
	           {
			Node *data = symtab_list.lookup_token($2);
			global_flag = true;
			if($1 != ret_type){
				yyerror("Function return type mismatch");
			}
			gen.returnValue(data->getvType());
			count = 0;
			symtab_list.pop();
			gen.in_block -= 1;
			ret_type = type_void;
		   };


function_variation: '(' mul_args  ')'
		    {
                    } 
                  | '('  ')'    
                    {
		    };
                  


mul_args:   mul_args ',' sgl_args | sgl_args
            {
	//	Trace("Reducing to mul_args\n");
            };	


sgl_args:   data_type ID 
	    {
		Node *data = new Node($2, Argument, $1);
		para_vector.push_back(data);
            }; 


inside_function:   inside_function variable_choice
	           {
	           }
                 |
	           inside_function constant_choice
		   {
		   }
  		 |
                   inside_function statement_choice
		   {
		   } 
                 |
		   {
		   };

variable_choice: data_type identifier_list ';' 
	         {	
			
			for(int i=0, j=0; i<var_vector.size(); i++){
				var_vector[i]->setvType($1);
				if(global_flag){
					var_vector[i]->setScope("global");
					if(var_vector[i]->getAssign()){
					    var_vector[i]->setValue(var_assign_vector[j]->getValue());
					    gen.globalVarValue(var_vector[i]);
 				        }else{
					    gen.globalVar(var_vector[i]);
					}
				}else{
					var_vector[i]->setScope("local");
					var_vector[i]->setNum(count++);
					if(var_vector[i]->getAssign()){
					    var_vector[i]->setValue(var_assign_vector[j]->getValue());
					    gen.localVarValue(var_vector[i]);
					}
				}
				symtab_list.insert_token(var_vector[i]);
				if(var_vector[i]->getAssign())
				{
					if(var_vector[i]->getvType() != var_assign_vector[j++]->getvType()){
					yyerror("LHS and RHS datatype mismatch");
			    }
				}
			}
			var_assign_vector.clear();
			var_vector.clear();
		 };

identifier_list: identifier_list ',' identifier_decl 
	         {
                 }
               | identifier_decl
                 {
                 };

identifier_decl: ID 
	         {
			Node *data = new Node($1, Variable, type_void);
			var_vector.push_back(data);
                 }
 		| ID '=' expression 
                 {
			Node *data = new Node($1, Variable, type_void);
			data->setAssign(true);
			var_vector.push_back(data);
			var_assign_vector.push_back($3);
                 }
                | ID '['INT_CONST']' 
                 {
			Node *data = new Node($1, Variable, type_void);
			var_vector.push_back(data);
                 }  
                | ID '['ID']' 
                 {
			Node* n = symtab_list.lookup_token($3);
			if(n == NULL){
				yyerror("This id isn't exist");	
			}
			if(n->getvType() != type_integer){
				yyerror("Array index isn't integer");
			}
			Node *data = new Node($1, Variable, type_void);
			var_vector.push_back(data);
                 }; 

                    
constant_choice:   CONST data_type ID '=' expression ';'
                   {
			if($2 != $5->getvType()){
				yyerror("LHS and RHS mismatch");
			}
			Node *data = new Node($3, Constant, $2);
			data->setValue($5->getValue());
			symtab_list.insert_token(data);
                   }  
                   
statement_choice:    simple_statement | conditional_statement | loop_statement;

simple_statement:    call_function ';'
		     {
		     }
		   | no_semi_statement ';' 
                     {
                     }
                   | PRINT
                     {
			gen.printStart();
                     }  
                     print_choice
                     {
			gen.printOutput($3->getvType());
                     } 
	           | PRINTLN
                     {
			gen.printStart();
                     }
                     print_choice
                     {
			gen.printOutput($3->getvType());
                     }
		   | READ ID ';' 
                     {
                     }
                   | RETURN expression ';'
                     {
			ret_type = $2->getvType();
			operation_flag = false;
                     }
                   | RETURN ';'
                     {
			ret_type = type_void;
                     };

no_semi_statement: no_semi_assign {$$ = $1;} | no_semi_ADD_SUB {$$ = $1;};
no_semi_assign: ID '=' expression 
	        {
			Node *data = symtab_list.lookup_token($1);
			if(data == NULL){yyerror("Identifier Not Found");}
			if(data->geteType() == Constant){
				yyerror("Constant can't reassign");
			}
			if(data->getvType() != $3->getvType()){
				yyerror("LHS and RHS mismatch");
			}

			if($3->geteType() != Function && !operation_flag){
				gen.expression_handle($3, "example");
			}

			string output = "";
			if(data->getScope() == "global"){
				output += "putstatic ";
				if(data->getvType() == type_integer){
					output += "int ";
				}else if(data->getvType() == type_bool){
					output += "bool ";
				}
				output += "example.";
				output += data->getIdentifier();
				output += "\n";
			}else{
				output += "istore ";
				output += to_string(data->getNum());
				output += "\n";
			}
			gen.assign(output);
			operation_flag = false;
			$$ = data;

		};  
no_semi_ADD_SUB: expression ADD %prec UMINUS
	         {
			
			gen.expression_handle($1, "example");
			gen.assign("iconst1\n");
                        gen.operation("iadd\n");

			string output = "";
			if($1->getScope() == "global"){
				output += "putstatic";
				if($1->getvType() == type_integer){
					output += "int ";
				}else if($1->getvType() == type_bool){
					output += "bool ";
				}
				output += "example.";
				output += $1->getIdentifier();
				output += "\n";
			}else{
				output += "istore ";
				output += to_string($1->getNum());
				output += "\n";
			}
			gen.assign(output);
			operation_flag = false;
		 } 
	       | expression SUB %prec UMINUS
		 {
			gen.expression_handle($1, "example");
			gen.assign("iconst1\n");
                        gen.operation("isub\n");

			string output = "";
			if($1->getScope() == "global"){
				output += "putstatic";
				if($1->getvType() == type_integer){
					output += "int ";
				}else if($1->getvType() == type_bool){
					output += "bool ";
				}
				output += "example.";
				output += $1->getIdentifier();
				output += "\n";
			}else{
				output += "istore ";
				output += to_string($1->getNum());
				output += "\n";
			}
			gen.assign(output);
			operation_flag = false;
		 } 
	       | ADD expression %prec UMINUS 
               | SUB expression %prec UMINUS;


print_choice:        expression ';'
                     {
			if(!operation_flag)
				gen.expression_handle($1, "example");
			operation_flag = false;
			$$ = $1;
                     }	;
	             
                         
                           
                         


conditional_statement:  IF '(' bool_expression ')'
		        {  
				symtab_list.push();
				gen.beginif(L_count);
				L_count += 2;
                        }
                        block_or_simple_conditional
                        {
				symtab_list.pop();
                        }
		        else_choice
		        {
                           /* Trace("Reducing to conditional_statement\n");*/		               };


else_choice:         ELSE
	             {
				gen.beginelse(L_count);
				L_count += 1;
				symtab_list.push();
                     }
	             block_or_simple_conditional
                     {
				gen.closeif(L_count);
				L_count += 1;
				symtab_list.pop();
                     }
                     | 
	             {
				gen.closeif(L_count);
				L_count += 1;
		     };


block_or_simple_conditional: '{' inside_block_conditional '}'
			     {
                             }
			   | statement_choice
                             {
                             };


inside_block_conditional:    inside_block_conditional statement_choice |                                    inside_block_conditional constant_choice  |		                           inside_block_conditional variable_choice  | 
			     {
                             //Trace("Reducing to inside_block_conditional\n");
                             };

loop_statement:      WHILE
	             {
			gen.beginWhile(L_count);
			L_count += 1;	
			symtab_list.push();
                     } 
                     '(' bool_expression  ')'
	             {
			gen.insideWhile(L_count);
			L_count += 2;
                     }
                     block_or_simple_loop 
                     {
			gen.closeWhile(L_count);
			L_count += 1;
			symtab_list.pop();
                     }
                   | FOR'(' no_semi_statement ';' 
		     {
			gen.beginWhile(L_count);
			L_count += 1;
		     }
		     bool_expression ';'
		     {
			gen.insideWhile(L_count);
		    	L_count += 2;
		     } 
		     no_semi_statement ')' 
                     {
			symtab_list.push();
                     }
                     block_or_simple_loop                    
                     {
		        gen.closeWhile(L_count);
			L_count += 1;
			symtab_list.pop();
		     }
		   | FOREACH '(' ID ':' ID DD ID ')'
                     {
			Node *data = new Node($3, Variable, type_integer);
			symtab_list.push();
 		     }
		     block_or_simple_loop
		     {
				symtab_list.pop();
		     }
		   | FOREACH '(' ID ':' INT_CONST DD ID ')'
		     {
				symtab_list.push();
		     }
 		     block_or_simple_loop
		     {
				symtab_list.pop();
		     }
		   | FOREACH '(' ID ':' ID DD INT_CONST ')'
		     {
			Node *data = symtab_list.lookup_token($3);
			string output = "";
			output += "sipush ";
			output += to_string($7);
			output += "\n\t\tistore ";
			output += to_string(data->getNum());
			output += "\n";
			gen.beginFor(output, L_count);
			L_count += 1;

			output = "";
			output += "iload ";
			output += to_string(data->getNum());
			output += "\n\t\tsipush ";
			output += to_string($7);
			output += "\n\t\tisub\n\t\tifel";
			gen.insideFor(output, L_count);
			L_count += 2;
			symtab_list.push();
		     }
		     
		     block_or_simple_loop
		     {
			Node *data = symtab_list.lookup_token($3);
			string output = "";
			output+="iload ";
			output+=to_string(data->getNum());
			output+="\n\t\tsipush ";
			output+="\n\t\tiadd\n\t\tistore ";
			output+=to_string(data->getNum());
			output+="\n";
			gen.closeFor(output, L_count);
			symtab_list.pop();
			L_count+=1;
		     }
		   | FOREACH '(' ID ':'  INT_CONST DD INT_CONST ')'
		     {
				symtab_list.push();
		     }
		     block_or_simple_loop
		     {
				symtab_list.pop();
 		     };


block_or_simple_loop: '{' inside_block_loop  '}'
		      {
 		      }
                     | statement_choice |
		       BREAK | CONTINUE
                      {
                      };


inside_block_loop:  inside_block_loop statement_choice |
                    inside_block_loop variable_choice  |
                    inside_block_loop constant_choice  |
	       	    inside_block_loop BREAK            | 
	       	    inside_block_loop CONTINUE         |
                    {/*Trace("Reducing to inside_block_loop\n");*/};


call_function:      ID '(' check_call_function_argument ')'
	            {
                        Node *data = symtab_list.lookup_token($1);
			if(data->func_para.size() != argu_vector.size()){
				yyerror("parameter and argument mismatch");
			}
			for(int i=0; i<argu_vector.size(); i++){
				if(data->func_para[i] != argu_vector[i]){
				    yyerror("parameter and argument mismatch");
				}
			}
			argu_vector.clear();
			gen.callFun("example", data);
			$$ = data;
                    };


check_call_function_argument: comma_seperated_arguments | ;


comma_seperated_arguments: comma_seperated_arguments ',' call_function_parameter | call_function_parameter ;


call_function_parameter: expression
		         {
				argu_vector.push_back($1->getvType());
				gen.expression_handle($1, "example");
                         };


expression: call_function
	    {
                $$ = $1;
            }
	  | ID
            {
		Node* data = symtab_list.lookup_token($1);
		if(data == NULL) {yyerror("Identifier Not Found");}
		$$ = data;
            }
	  | '(' expression  ')' | calculation_expression
	  | constant_values
            {
	         $$ = $1;	
	    } 
	  | ID '[' INT_CONST ']'
            {
		Node* data = symtab_list.lookup_token($1);
		if(data == NULL) {yyerror("Identifier Not Found");}
		$$ = data;
	    }
	  | ID '[' ID ']'
            {
		Node* data2 = symtab_list.lookup_token($3);
		if(data2->getvType() != type_integer){
			yyerror("Array Argument isn't integer");
		}
		Node* data = symtab_list.lookup_token($1);
		if(data == NULL) {yyerror("Identifier Not Found");}
		$$ = data;
	    };

calculation_expression: '-' expression %prec UMINUS
		        {
				operation_flag = true;
				gen.expression_handle($2, "example");
				gen.negativeIint("ineg\n");
				Node* data = $2;
				$2->setValue($2->getValue() * (-1));
				$$ = data;
                        }
                        | no_semi_ADD_SUB
                        | expression '*' expression
                        {
                            if($1->getvType() != $3->getvType()){
                                yyerror("Operand datatype mismatch");
                            } 
                            operation_flag = true;
                            gen.expression_handle($1, "example");
                            gen.expression_handle($3, "example");
                            gen.operation("imul\n");
                            $1->setValue($1->getValue() + $3->getValue());
                            $$ = $1;
			    
                        }   
		        | expression '/' expression
                        {
                            if($1->getvType() != $3->getvType()){
                                yyerror("Operand datatype mismatch");
                            } 
                            operation_flag = true;
                            gen.expression_handle($1, "example");
                            gen.expression_handle($3, "example");
                            gen.operation("idiv\n");
                            $1->setValue($1->getValue() + $3->getValue());
                            $$ = $1;
                        }
                        | expression '%' expression       
                        {
                            if($1->getvType() != $3->getvType()){
                                yyerror("Operand datatype mismatch");
                            } 
                            operation_flag = true;
                            gen.expression_handle($1, "example");
                            gen.expression_handle($3, "example");
                            gen.operation("irem\n");
                            $1->setValue($1->getValue() + $3->getValue());
                            $$ = $1;
                        }
          		| expression '+' expression
		        {
                            if($1->getvType() != $3->getvType()){
                                yyerror("Operand datatype mismatch");
                            } 
                            operation_flag = true;
                            gen.expression_handle($1, "example");
                            gen.expression_handle($3, "example");
                            gen.operation("iadd\n");
                            $1->setValue($1->getValue() + $3->getValue());
                            $$ = $1;
                        }
		        | expression '-' expression        
         	        {
                            if($1->getvType() != $3->getvType()){
                                yyerror("Operand datatype mismatch");
                            } 
                            operation_flag = true;
                            gen.expression_handle($1, "example");
                            gen.expression_handle($3, "example");
                            gen.operation("isub\n");
                            $1->setValue($1->getValue() + $3->getValue());
                            $$ = $1;
                        };


bool_expression: relational_expression | logical_expression;


relational_expression:  expression '<' expression 
		     {
		     	 gen.expression_handle($1, "example");
                         gen.expression_handle($3, "example");
                         gen.operation("isub\n");           
                         gen.operation("iflt");   
                     }
		     | expression LEQ expression 
                     {
                     	  gen.expression_handle($1, "example");
                         gen.expression_handle($3, "example");
                         gen.operation("isub\n");            
                         gen.operation("ifle");    
                     }
                     | expression '>' expression
                     {
                    	  gen.expression_handle($1, "example");
                         gen.expression_handle($3, "example");
                         gen.operation("isub\n");            
                         gen.operation("ifgt");
                     }
                     | expression GEQ expression 
                     {
                         gen.expression_handle($1, "example");
                         gen.expression_handle($3, "example");
                         gen.operation("isub\n");            
                         gen.operation("ifge");
                     }
                     | expression EQ expression 
                     {
                     	  gen.expression_handle($1, "example");
                         gen.expression_handle($3, "example");
                         gen.operation("isub\n");            
                         gen.operation("ifeq"); 
                     }
                     | expression NEQ expression
                     {
                    	  gen.expression_handle($1, "example");
                         gen.expression_handle($3, "example");
                         gen.operation("isub\n");            
                         gen.operation("ifne");
                     };


logical_expression:  expression
                     {
			if($1->getvType() != type_bool){
				yyerror("exp type isn't boolean");
			}
			 Node* temp = new Node();
                        temp->setConstant(true);
                        temp->setValue(1);
                        temp->setvType(type_integer);
                        gen.expression_handle($1, "example");
                        gen.expression_handle(temp, "example");
                        gen.operation("isub\n");            
                        gen.operation("ifeq");   
		     }
                     |'!' expression 
                     {
			if($2->getvType() != type_bool){
				yyerror("exp type isn't boolean");
			}
			$2->setValue($2->getValue() * -1);
                        Node* temp = new Node();
                        temp->setConstant(true);
                        temp->setValue(1);
                        temp->setvType(type_integer);
                        gen.expression_handle($2, "example");
                        gen.expression_handle(temp, "example");
                        gen.operation("isub\n");            
                        gen.operation("ifeq");	
                     }
                     | expression AND expression
                     {
                     	  gen.expression_handle($1, "example");
                         gen.expression_handle($3, "example");
                         gen.operation("iand\n");            
                         gen.operation("ifne");   
                     }
		     | expression OR expression
                     {
                     	  gen.expression_handle($1, "example");
                         gen.expression_handle($3, "example");
                         gen.operation("ior\n");            
                         gen.operation("ifne");
                     }
                     | bool_expression OR bool_expression
		     {
		     }
                     | bool_expression AND bool_expression
		     {
		     }; 


constant_values:         INT_CONST
	                 {
			       Node* data = new Node("",Constant,type_integer);
			       data->setValue($1);
			       data->setvType(type_integer);
			       $$ = data;
                         }
                       | REAL_CONST
			 {
			       Node* data = new Node("",Constant,type_real);
			       data->setvType(type_real);
			       $$ = data;
 			 }
                       | BOOL_CONST
                         {
			       Node* data = new Node("",Constant,type_bool);
			       
			       if($1 == true)
				   data->setValue(1);
			       else
				   data->setValue(0);
			       data->setvType(type_bool);
			       $$ = data;
                         }
                       | STR_CONST
                         {
			       Node* data = new Node("",Constant,type_string);
			       data->setValue_string($1);		
			       data->setvType(type_string);
      			       $$ = data;
                         };
                           
	                


data_type:  INT    {$$ = type_integer;}
         |  FLOAT  {$$ = type_real;}
         |  BOOL   {$$ = type_bool;}
         |  STRING {$$ = type_string;}
         |  VOID   {$$ = type_void;};
	   



                
%%

void yyerror(const char *msg)
{
   printf("[ERROR]: %s\n", msg);
   exit(0);
}

int main(int argc, char **argv)
{
    /* open the source program file */
    if (argc != 2) {
        printf ("Usage: sc filename\n");
        exit(1);
    }
    yyin = fopen(argv[1], "r");         /* open input file */

    
    gen.file.open("test.txt",ios::out);
    if(gen.file.fail())
       cout << "File Fail\n";
    gen.in_block -= 1;   
    gen.beginProgram("example");
    gen.in_block += 1;
    if (yyparse() == 1){                
        yyerror("Parsing error !");
    }

    gen.in_block -= 1;   
    gen.closeProgram();

    Node* n = symtab_list.lookup_token("main");
    if(n == NULL){yyerror("Don't have main function");}
    symtab_list.dump_all();
    


}
