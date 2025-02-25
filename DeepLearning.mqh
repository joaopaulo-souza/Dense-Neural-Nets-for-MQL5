#include <DeepLearningLibrary.mqh>

class DeepLearning
  {
public:
   //-------------------------------
   // Define the cost functions and its derivatives
   class Loss;
   // Define metrics for evaluation
   class Metrics;
   
   //-------------------------------
   // Dense Connected Layer
   class DenseLayer;
   // Activation Function Layer 
   class ActivationLayer;
   // Softmax function Layer
   class SoftmaxLayer;
   // Dropout Layer to Enhance Overffiting
   class DropoutLayer;

   
   
   //Methods
   virtual matrix    Output(matrix &X)                {return X*0;   }
   virtual matrix    GradDescent(matrix &Ey)          {return Ey*0;  }
   virtual void      Update(void)                     {              }
   virtual void      SaveWeights(int k,string IAname) {              }
   virtual void      LoadWeights(int k,string IAname) {              }
   virtual void      SetDrop(double Drop)             {              }
   virtual void      SetAdam(double B1, double B2, double Alph) {    }
   
   
   
   //=============================
   matrix   InitWeights(matrix &M);
   matrix   ZeroMatrix(matrix &M);
   void     SaveMatrix(matrix &M, string M_name);
   matrix   LoadMatrix(string M_name);
   matrix   Concatenate(matrix &X, matrix &H);
   
   
   //Activation
   matrix Sig(matrix &X);
   matrix Tanh(matrix &X);
   matrix ReLU(matrix &X);
   
   matrix dSig(matrix &X);
   matrix dTanh(matrix &X);
   matrix dReLU(matrix &X);
   
   //ADAM optimizer
   matrix AdamM(matrix &m, matrix &dX,double beta1);
   matrix AdamV(matrix &v, matrix &dX,double beta2);
   matrix Adam(double it, matrix &m, matrix &v,double beta1, double beta2, double alpha);
   
   
  };
 
//+------------------------------------------------------------------+
//|   Deep Learning Methodes                                         |
//+------------------------------------------------------------------+
matrix DeepLearning::InitWeights(matrix &M)
{
   matrix W;
   W = M;
   for(int i=0;i<W.Rows();i++)
     {for(int j=0;j<W.Cols();j++)
        {W[i][j] = (2.0*(MathRand()/32766.0) -1.0);}}
         
return W;
}
matrix DeepLearning::ZeroMatrix(matrix &M)
{
for(int i=0;i<M.Rows();i++)
  {for(int j=0;j<M.Cols();j++)
     {M[i][j] = 0;}}
      
return M;
}
void DeepLearning::SaveMatrix(matrix &M,string M_name)
{
   //transforma a matrix M num vetor de strings
   ulong Srows , SCols;
   Srows = M.Rows();
   SCols = M.Cols();
   string csv_name;
   csv_name = M_name;
   
   string V[];
   ArrayResize(V,Srows);
   
   //Zera o vetor de strings
   for(int i=0;i<ArraySize(V);i++)
     {V[i] = NULL;}
      
   //Prepara o vetor com as classes 

   for(int i=0;i<Srows;i++)
     {for(int j=0;j<SCols;j++)
         {
         if(j == SCols-1) V[i] = V[i] + DoubleToString(M[i][j]);
         else V[i] = V[i] + DoubleToString(M[i][j]) + ",";}}     
   
   //Abre o arquivo para ser escrito
   int h=FileOpen(csv_name,FILE_WRITE|FILE_ANSI|FILE_CSV);
   //Se o arquivo não é aberto devidamente o handle é inválido
   if(h==INVALID_HANDLE) Alert("Error opening file");
   
   for(int i=0;i<Srows;i++)
      {
      FileWrite(h,V[i]);
      }
   FileClose(h);
}
matrix DeepLearning::LoadMatrix(string M_name)
{
   //Le apenas a primeira linha para saber o número de colunas
   string L1;
   string csv_name;
   csv_name = M_name;
   //Abre o arquivo para ser lido
   int h1=FileOpen(csv_name,FILE_READ|FILE_ANSI|FILE_TXT);
   //Se o arquivo não é aberto devidamente o handle é inválido
   if(h1==INVALID_HANDLE)   Alert("Error opening file");
   L1 = FileReadString(h1);
   FileClose(h1);
   
   //L1 possui agora a primeira linha da matriz
   //Lê quantas colunas são pelo número de vírgulas
   
   int num_columns = 1; 
   
   for(int i=0;i<L1.Length();i++)
     {
      if(L1.Substr(i,1) == ",") num_columns++;
     }
   
   //Abre o arquivo para ser lido
   int h=FileOpen(csv_name,FILE_READ|FILE_ANSI|FILE_CSV,",");
   //Se o arquivo não é aberto devidamente o handle é inválido
   if(h==INVALID_HANDLE)   Alert("Error opening file");

   string read_x;
   string m[]; //Vetor que receberá os dados
   int    m_size = 0;
   
   matrix A;   // Matriz que retornará com os dados
   int A_size = 0;
   //Começa com a leitura da primeira linha
   
   while(!FileIsEnding(h))
   {
      ArrayResize(m,m_size+1);
      read_x = FileReadString(h);   // Lê o conteudo até a virgula é passa pra próxima
      m[m_size] = read_x;
   if(!FileIsEnding(h)) m_size++;  
   }
   FileClose(h);
   
   int num_rows;
   num_rows = (m_size + 1)/num_columns;
   
   if(((m_size +1)% num_columns) != 0 )   Alert("Error the matrix data is incomplete");
   else
   {
   
   //Preparar a Matriz A
   A.Init(num_rows,num_columns);
   
   for(int i=0;i<num_rows;i++)
      {for(int j=0;j<num_columns;j++)
        {A[i][j] = StringToDouble(m[i * num_columns + j]);}}         
   //==========
   }
return A;
}
matrix DeepLearning::Concatenate(matrix &X,matrix &H)
{
if(X.Cols() != H.Cols()) Alert("The number of Cols of X and H must be equal");

matrix M;
M.Init(X.Rows() + H.Rows(),X.Cols());

ulong lim;
lim = X.Rows();

for(int i=0;i<M.Rows();i++)
  {for(int j=0;j<M.Cols();j++)
     {if(i < lim) M[i][j] = X[i][j];
      if(i >= lim) M[i][j] = H[i-lim][j];}}
      
return M;
}


//+------------------------------------------------------------------+
//|    Activation Methodes                                           |
//+------------------------------------------------------------------+

matrix DeepLearning::Sig(matrix &X)
{
matrix M;
M = X;
for(int i=0;i<M.Rows();i++)
  {for(int j=0;j<M.Cols();j++)
     {M[i][j] = 1.0/(1.0 + MathExp((-1)*M[i][j]));}}
     
return M;
      
}
matrix DeepLearning::Tanh(matrix &X)
{
matrix M;
M = X;
for(int i=0;i<M.Rows();i++)
  {for(int j=0;j<M.Cols();j++)
     {M[i][j] = (MathExp(M[i][j])-MathExp((-1.0)*M[i][j]))/(MathExp(M[i][j])+MathExp((-1.0)*M[i][j]));}}
     
return M;
}
matrix DeepLearning::ReLU(matrix &X)
{
matrix M;
M = X; 
for(int i=0;i<M.Rows();i++)
  {for(int j=0;j<M.Cols();j++)
     {if(M[i][j] > 0) M[i][j] = M[i][j];
      if(M[i][j] <=0) M[i][j] = 0.01*M[i][j];}}

return M;     
}

matrix DeepLearning::dSig(matrix &X)
{
matrix M;
M = X; 

M = Sig(M);
for(int i=0;i<M.Rows();i++)
  {for(int j=0;j<M.Cols();j++)
     {M[i][j] = M[i][j]*(1.0 - M[i][j]);}}

return M;  
}
matrix DeepLearning::dTanh(matrix &X)
{
matrix M;
M = X; 

M = Tanh(M);
for(int i=0;i<M.Rows();i++)
  {for(int j=0;j<M.Cols();j++)
     {M[i][j] = (1.0 - M[i][j]*M[i][j]);}}

return M;  
}
matrix DeepLearning::dReLU(matrix &X)
{
matrix M;
M = X;
for(int i=0;i<M.Rows();i++)
  {for(int j=0;j<M.Cols();j++)
     {if(M[i][j] > 0) M[i][j] = 1;
      if(M[i][j] <= 0) M[i][j] = 0.01;}}
      
return M;
}
//+------------------------------------------------------------------+
//|   Optimizers                                                     |
//+------------------------------------------------------------------+
matrix DeepLearning::AdamM(matrix &m, matrix &dX,double beta1)
{
matrix mt;
mt.Init(dX.Rows(),dX.Cols());
mt = m * beta1;
mt = mt + dX * (1-beta1);
return mt;
}
matrix  DeepLearning::AdamV(matrix &v, matrix &dX,double beta2)
{
matrix vt;
vt = beta2*v;
vt = vt + dX * dX * (1-beta2);
return vt; 
}
matrix DeepLearning::Adam(double it, matrix &m, matrix &v,double beta1,double beta2, double alpha)
{
matrix D, mt, vt; 

mt = m * (1/(1-MathPow(beta1,it)));
vt = v * (1/(1-MathPow(beta2,it)));

vt = MathSqrt(vt) + 1e-8; 
D = m / vt;
D = D * alpha;
return D; 
}

#include <DenseLayer.mqh>
#include <DropoutLayer.mqh>
#include <ActivationLayer.mqh>
#include <SoftmaxLayer.mqh> 
#include <Metrics.mqh>
#include <Loss.mqh>









