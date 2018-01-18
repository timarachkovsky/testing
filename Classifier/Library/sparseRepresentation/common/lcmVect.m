function cm = lcmVect(numbers)
cm = 1;
if numel(numbers) < 2
   warning('It''s too low numbers to count lcm!');
   return;
end
    for i = 1:numel(numbers)
        cm = lcm(cm, numbers(i));
    end
end