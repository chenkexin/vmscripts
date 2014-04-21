import sys
import os
import string



file = open("summary.txt")
lines = file.readlines()
f = open("temp1.txt", "w");
for line in lines:
  #line.split('\t')
   term = line.split('\t')
   t =  term[0].split('_')
   if sys.argv[2] in t:
     term[0] = t[1] + " " + t[2]+ " "+t[3]
     f.write(string.join(term))

f = open("temp1.txt")
filename = "result_"+sys.argv[2]+"_"+sys.argv[3]+".dat"
f2= open(filename, "w+");
lines = f.readlines()
g_counter = 1
g_newline = ""
f2.write("type  noop deadline cfq\n")
for line in lines:
  term = line.split(" ")
  if sys.argv[3] in term:
    if g_counter == 1:
      g_newline += term[0]
      g_newline += " "
      g_newline += term[4].split("=")[1].split("K")[0]
      g_counter += 1
      continue
    if g_counter ==2:
      g_newline +=" "
      g_newline += term[4].split("=")[1].split("K")[0]
      g_counter+=1
      continue
    if g_counter == 3:
      g_newline += " "
      g_newline += term[4].split("=")[1].split("K")[0]
      g_newline += "\n"
      f2.write(g_newline)
      g_newline= ""
      g_counter = 1
      continue
    
