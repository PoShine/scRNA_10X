## 
### ---------------
###
### Create: Jianming Zeng
### Date: 2019-07-24 15:03:19
### Email: jmzeng1314@163.com
### Blog: http://www.bio-info-trainee.com/
### Forum:  http://www.biotrainee.com/thread-1376-1-1.html
### CAFS/SUSTC/Eli Lilly/University of Macau
### Update Log: 2019-07-24  First version
###
### ---------------

# 因为作者在GEO上面公布了自己处理好的表达矩阵
# 所以自己下载sra文件，转fq格式，走cellranger流程并不是必须
# 这里简要展示多个10x的cellranger结果如何整合。

# 因为文章使用的是Seurat2.0，所以这里就展示

library(Seurat)
sce.10x <- Read10X(data.dir = '~/Documents/10x/cellranger/four-PBMC-mtx/SRR7722939/')
sce1 <- CreateSeuratObject(raw.data = sce.10x, 
                           min.cells = 60, 
                           min.genes = 200, 
                           project = "SRR7722939") 
sce1
sce.10x <- Read10X(data.dir = '~/Documents/10x/output/four-PMMC-mtx/SRR7722940/')
sce2 <- CreateSeuratObject(raw.data = sce.10x, 
                           min.cells = 60, 
                           min.genes = 200, 
                           project = "SRR7722940") 
sce2
sce.10x <- Read10X(data.dir = '~/Documents/10x/output/four-PMMC-mtx/SRR7722941/')
sce3 <- CreateSeuratObject(raw.data = sce.10x, 
                           min.cells = 60, 
                           min.genes = 200, 
                           project = "SRR7722941") 
sce3
sce.10x <- Read10X(data.dir = '~/Documents/10x/output/four-PMMC-mtx/SRR7722942/')
sce4 <- CreateSeuratObject(raw.data = sce.10x, 
                           min.cells = 60, 
                           min.genes = 200, 
                           project = "SRR7722942") 
sce4


## timePoints
##   PBMC_ARD614 PBMC_EarlyD27      PBMC_Pre PBMC_RespD376 
##          4516          1592          2082          4684
# 
# | GSM3330561 | PBMC Pre |
# | GSM3330562 | PBMC Disc Early |
# | GSM3330563 | PBMC Disc Resp |
# | GSM3330564 | PBMC Disc AR |

sce1;sce2;sce3;sce4

  
sce1@meta.data$group <- "PBMC_Pre"
sce2@meta.data$group <- "PBMC_EarlyD27"
sce3@meta.data$group <- "PBMC_RespD376"
sce4@meta.data$group <- "PBMC_ARD614"

head(colnames(sce1@data))
colnames(sce1@data) <- paste0("PBMC_Pre.",colnames(sce1@data))
head(colnames(sce1@data))
colnames(sce2@data) <- paste0("PBMC_EarlyD27.",colnames(sce2@data))
colnames(sce3@data) <- paste0("PBMC_RespD376.",colnames(sce3@data))
colnames(sce4@data) <- paste0("PBMC_ARD614.",colnames(sce4@data))


# Set up
sce1 <- NormalizeData(sce1)
sce1 <- ScaleData(sce1, display.progress = F) 
sce2 <- NormalizeData(sce2)
sce2 <- ScaleData(sce2, display.progress = F) 
sce3 <- NormalizeData(sce3)
sce3 <- ScaleData(sce3, display.progress = F) 
sce4 <- NormalizeData(sce4)
sce4 <- ScaleData(sce4, display.progress = F) 

# Gene selection for input to CCA
sce1 <- FindVariableGenes(sce1, do.plot = F)
sce2 <- FindVariableGenes(sce2, do.plot = F)
sce3 <- FindVariableGenes(sce3, do.plot = F)
sce4 <- FindVariableGenes(sce4, do.plot = F)

g.1 <- head(rownames(sce1@hvg.info), 1000)
g.2 <- head(rownames(sce2@hvg.info), 1000)
g.3 <- head(rownames(sce3@hvg.info), 1000)
g.4 <- head(rownames(sce4@hvg.info), 1000)

genes.use <- unique(c(g.1, g.2,g.3, g.4))
genes.use <- intersect(genes.use, rownames(sce1@scale.data))
genes.use <- intersect(genes.use, rownames(sce2@scale.data))
genes.use <- intersect(genes.use, rownames(sce3@scale.data))
genes.use <- intersect(genes.use, rownames(sce4@scale.data))
head(genes.use)
length(genes.use)
## 找到4个数据集，共同重要的基因进行后续合并分析。

head(colnames(sce1@data))
colnames(sce1@data) <- paste0("PBMC_Pre.",colnames(sce1@data)) 
colnames(sce2@data) <- paste0("PBMC_EarlyD27.",colnames(sce2@data))
colnames(sce3@data) <- paste0("PBMC_RespD376.",colnames(sce3@data))
colnames(sce4@data) <- paste0("PBMC_ARD614.",colnames(sce4@data))

head(colnames(sce1@scale.data))
colnames(sce1@scale.data) <- paste0("PBMC_Pre.",colnames(sce1@data)) 
colnames(sce2@scale.data) <- paste0("PBMC_EarlyD27.",colnames(sce2@data))
colnames(sce3@scale.data) <- paste0("PBMC_RespD376.",colnames(sce3@data))
colnames(sce4@scale.data) <- paste0("PBMC_ARD614.",colnames(sce4@data))

# Duplicate cell names, please provide 'add.cell.id1' and/or 'add.cell.id2' for unique names
# 这一步耗时很夸张, 保守估计10分钟。
# 重点就是 RunMultiCCA 函数，做 10X 数据集的合并。
sce.comb <- RunMultiCCA(list(sce1,sce2,sce3,sce4), 
                       add.cell.ids=c("PBMC_Pre.","PBMC_EarlyD27.","PBMC_RespD376.","PBMC_ARD614."),
                       genes.use = genes.use, 
                       num.cc = 30)

save(sce.comb,file = 'patient1-PBMAC.sce.comb.Rdata')

# visualize results of CCA plot CC1 versus CC2 and look at a violin plot
# 可以检查一下CCA, 类比PCA分析。
p1 <- DimPlot(object = sce.comb, 
              reduction.use = "cca", group.by = "group", 
              pt.size = 0.5, do.return = TRUE)
p2 <- VlnPlot(object = sce.comb, 
              features.plot = "CC1", 
              group.by = "group", 
              do.return = TRUE)
plot_grid(p1, p2)
ggsave('patient1-PBMAC.sce.comb_explore_CC.pdf')
PrintDim(object = sce.comb, reduction.type = "cca", 
         dims.print = 1:2, 
         genes.print = 10)
# 类比于PCA分析里面的JackStraw和PCElbowPlot查看挑选多个主成分合适。
# 耗时也很验证，五分钟左右。
p3 <- MetageneBicorPlot(sce.comb, grouping.var = "group", dims.eval = 1:30, 
                        display.progress = FALSE)
p3
ggsave('patient1-PBMAC.sce.comb_MetageneBicorPlot.pdf')

DimHeatmap(object = sce.comb, reduction.type = "cca", cells.use = 500, 
           dim.use = 1:9, do.balanced = TRUE)
ggsave('patient1-PBMAC.sce.comb_DimHeatmap.pdf')

# 有进度条报告测序运行情况，也需要五分钟。
sce.comb <- AlignSubspace(sce.comb, reduction.type = "cca", 
                          grouping.var = "group", 
                         dims.align = 1:20)

p1 <- VlnPlot(object = sce.comb, features.plot = "ACC1", group.by = "group", 
              do.return = TRUE)
p2 <- VlnPlot(object = sce.comb, features.plot = "ACC2", group.by = "group", 
              do.return = TRUE)
plot_grid(p1, p2)
ggsave('patient1-PBMAC.sce.comb_ACC.pdf')

# t-SNE and Clustering
sce.comb <- RunTSNE(sce.comb, reduction.use = "cca.aligned", dims.use = 1:20, 
                   do.fast = T)
sce.comb <- FindClusters(sce.comb, reduction.type = "cca.aligned", 
                        resolution = 1, dims.use = 1:20,print.output = 0)
# Visualization
p1 <- TSNEPlot(sce.comb, do.return = T, pt.size = 0.5, group.by = "group")
p2 <- TSNEPlot(sce.comb, do.label = T, do.return = T, pt.size = 0.5)
plot_grid(p1, p2)
ggsave('patient1-PBMAC.sce.comb_tSNE.pdf')

table(sce.comb@meta.data$res.1,sce.comb@meta.data$group)
 
save(sce.comb,file = 'patient1-PBMAC.sce.comb.second.Rdata')





