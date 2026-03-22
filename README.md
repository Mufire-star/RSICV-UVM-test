# RSICV-UVM-test
用于记录成功运行的alu和control unit模块的例子，对可以运行的版本做一个记录。

# alu文件夹
  该文件夹下是验证alu模块的一个示例；运行的时候先运行
```sh
  make compile
```
  之后会在 alu/run文件夹下生成 simv 文件
  对该文件运行下面的命令
```sh
  ./simv +fsdb_dump -l try_fsdb.log`
  ls -l simv.daidir wave.fsdb wave.vcd try_fsdb.log
```
  会生成`wave.fsdb`波形文件
  运行命令 `make clean` 清除生成的文件，运行前清除，避免报错
