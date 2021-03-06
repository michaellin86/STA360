##### Initialize Workspace #####
## Load Data ##
data=read.table('hier.txt')
Y = as.matrix(na.omit(data[,2:11]))
library(MCMCpack)

## Define Parameters ##
a = 5; lam = 4;
m0 = 12; s0 = 1; m1 = 1; s1 = 1;
xj = c(-4.5, -3.5, -2.5, -1.5, -0.5, 0.5, 1.5, 2.5, 3.5, 4.5)

# (Need only keep track of beta1, beta0) #
## Initialize Vector ##
n = dim(Y)[1]; p = dim(Y)[2];
N = 1000; B = 100;
beta0 = NULL
beta1 = NULL


##### Gibbs Sampler #####
for(i in 1:n){
  beta0.vec = rep(0, N+B)
  beta1.vec = rep(0, N+B)
  
  tau.vec = rinvgamma(3, shape = a, scale = lam)
  tau = tau.vec[1]
  tau0 = tau.vec[2]
  tau1 = tau.vec[3]
  
  yj = Y[i,]
  
  for(j in 1:(N+B)){
    mu0 = rnorm(1, m0, s0)
    mu1 = rnorm(1, m1, s1)
    
    beta0.temp = rnorm(1, (tau*mu0+tau0*sum(yj))/(tau+p*tau0/2), 
                       sqrt(tau*tau0/(tau+p*tau0)))
    beta1.temp = rnorm(1, (tau*mu1)/(tau+tau1*sum(xj^2)), 
                       sqrt(tau1*tau/(tau+tau1*sum(xj^2))))
    
    tau.vec = rinvgamma(3, shape = a, scale = lam+0.5*sum(yj^2)-
                          beta0.temp*sum(yj)-beta1.temp*sum(yj*xj)+
                          0.5*p*beta0.temp^2+0.5*beta1.temp^2*sum(xj^2))
    
    tau = tau.vec[1]
    tau0 = tau.vec[2]
    tau1 = tau.vec[3]
    
    beta0.vec[j] = beta0.temp
    beta1.vec[j] = beta1.temp
    
  }
  
  beta0 = rbind(beta0, beta0.vec)
  beta1 = rbind(beta1, beta1.vec)
    
}

## Post Burn In Sample ##
int = beta0[,(B+1):(B+N)]
slope = beta1[,(B+1):(B+N)]

## Slope > 0.5 ##
print(mean(slope>0.5))

##### Autocorrelation #####
int.acf = NULL
slope.acf = NULL
for(i in 1:n){  
  acf.temp = c(acf(int[i,], plot=F)[[1]])
  int.acf = rbind(int.acf, acf.temp)
  
  acf.temp = c(acf(slope[i,], plot=F)[[1]])
  slope.acf = rbind(slope.acf, acf.temp)  
}
print(mean(int.acf>slope.acf))