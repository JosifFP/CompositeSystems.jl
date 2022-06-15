using Plots,Distributions
p = μ / (λ + μ)
n = 1
X = rand(Bernoulli(p),5_000)
histogram(X,label = false)
var(X)
mean(X)