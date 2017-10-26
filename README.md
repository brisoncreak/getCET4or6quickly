# CUDA-lifegame生命游戏
Conway's Game of Life CUDA实现
## 环境
把bin文件夹中的文件glut32.dll和glut64.dll放在CUDA安装目录\bin文件夹中

把lib文件夹中的文件glut32.lib和glut64.lib放在CUDA安装目录\lib\Win32文件夹中

把common文件夹中的所有.h文件及子目录下文件放在CUDA安装目录\common文件夹中

> 相关文件来自《GPU高性能编程-CUDA实战（CUDA By Example）》

## 运行
将initdata数组的值赋值为1进行初始化

在generate_frame函数中通过修改ticks帧编号判断控制速度

