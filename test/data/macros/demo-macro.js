(function(){
  var d, x, y, tmp, k, ref$, v;
  x = 12;
  y = 1;
    tmp = x;
  x = y;
  y = tmp;;
  console.log(x, y);
    for (k in ref$ = system) {
    v = ref$[k];
    eval("var " + k + " = v");
  };
    export default d;
}).call(this);
