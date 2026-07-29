#######################################################################################################################################
#
# find.max.nclust
#
# R function to estimate the maximum number of groups in DAPC analysis. 
#
# contacts: duarte.ldas@gmail.com, renanmaestri@gmail.com
#
# Arguments:
#   - x: a data.frame or matrix object containing eigenvectors by sites data.
#   - threshold: the number of eigenvectors used to perform classification.
#   - runs = number of times classification will be performed.
#   - method= c("kmeans","ward"). See function 'find.clusters'of adegenet package.
#   - stat = c("BIC", "AIC", or "WSS"). See function 'find.clusters'of adegenet package.
#   - criterion = c("diffNgroup", "min","goesup", "smoothNgoesup", or "goodfit"). See function 'find.clusters'of adegenet package.
#   - max.nclust= Value of set of values defining the maximum number of groups to be evaluated.
#   - subset = number of cells used in the analysis. It is particularly important whenever the total number of cells is large (> 1000).
#   - confidence.level= threshold confidence level used to estimate congruence in the classification pattern.
#   
#
# Value: returns matrix containing congruence values ranging between 0-1 for each max.nclust value (see Arguments) and confidence level.
#
#######################################################################################################################################

library(adegenet)

############ Estimate the maximum number of groups for DAPC analysis #######################

find.max.nclust<-function(x,threshold,runs=100,method="kmeans",stat = "BIC",criterion = "diffNgroup",max.nclust=c(10,15,20,25,30),subset=100,confidence.level=c(0.7,0.8,0.9,0.95,0.99)){
  group.affinity<-matrix(NA,subset,subset)
  grouping<-matrix(NA,(subset*(subset-1))/2,runs)
  group.sample<-sample(1:nrow(x),size=subset,replace=FALSE)
  congruence<-matrix(NA,length(max.nclust),length(confidence.level),dimnames=list(paste("max.",max.nclust,"groups",sep=" "),paste("Confidence.level=",confidence.level,"%",sep="")))
  for (m in 1:length(confidence.level)){
    for (l in 1:length(max.nclust)){
      for (k in 1:runs){
        clust.vec<-adegenet::find.clusters(x[, 1:threshold],
                                           clust = NULL,
                                           choose.n.clust = FALSE,
                                           n.pca = threshold,
                                           method = method,
                                           stat = stat,
                                           n.iter = 1e7,
                                           criterion = criterion,
                                           max.n.clust = max.nclust[[l]]
        )
        rownames(as.data.frame(clust.vec$grp)) == rownames(esp)
        groups<-as.matrix(clust.vec$grp)
        group.subset<-as.matrix(groups[group.sample,])
        tgroups<-as.matrix(t(group.subset))
        for(j in 1:subset){
          for (i in 1:subset){
            group.affinity[i,j]<-group.subset[i,]==tgroups[,j]
          }
        }
        grouping[,k]<-as.vector(as.dist(group.affinity,diag=FALSE,upper=FALSE))
      }
      cor.grouping<-as.matrix(cor(grouping))
      diag(cor.grouping)<-NA
      congruence[l,m]<-sum(ifelse(rowMeans(cor.grouping,na.rm=T)>confidence.level[[m]],1,0))/runs
    }
  }  
  congruence
}