type file;

app (file out) wordcount (file script, file input)
{
    python @script @input stdout=@out;
}

file inputs[]    <filesys_mapper; location="inputs">;
file script      <single_file_mapper; file="/home/ubuntu/Wordcount.py">;

foreach input,i in inputs
{
  file out <single_file_mapper; file=strcat("output/foo_",i,".out")>;
  out = wordcount (script, input);
}

