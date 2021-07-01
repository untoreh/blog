+++
date = "6/29/2021"
title = "Shades of Colors"
tags = ["programming"]
rss_description = "Take a from black-white to colored gradient"
+++

This is some javascript that I wrote such that starting from a website, themed with shades of gray, you end up with gradient based on an accent color. Coupled with a color picker tool, a website can offer on-the-fly _user based_ theming customization.

```javascript
//function to return the color in hex value
        $.cssHooks.bgColor = {
                get: function(elem) {
                        if (elem.currentStyle)
                                var bg = elem.currentStyle["backgroundColor"];
                        else if (window.getComputedStyle)
                                var bg = document.defaultView.getComputedStyle(elem,
                                        null).getPropertyValue("background-color");
                        if (bg.search("rgb") == -1)
                                return bg;
                        else {
                                bg = bg.match(/^rgb\((\d+),\s*(\d+),\s*(\d+)\)$/);
                                function hex(x) {
                                        return ("0" + parseInt(x).toString(16)).slice(-2);
                                }
                                return hex(bg[1]) + hex(bg[2]) + hex(bg[3]);
                        }
                }
        }

        //function to make colors brighter or darker

        function shadeColor(color, porcent) {

                var R = parseInt(color.substring(1,3),16)
                var G = parseInt(color.substring(3,5),16)
                var B = parseInt(color.substring(5,7),16);

                R = parseInt(R * (100 + porcent) / 100);
                G = parseInt(G * (100 + porcent) / 100);
                B = parseInt(B * (100 + porcent) / 100);

                R = (R<255)?R:255;
                G = (G<255)?G:255;
                B = (B<255)?B:255;

                var RR = ((R.toString(16).length==1)?"0"+R.toString(16):R.toString(16));
                var GG = ((G.toString(16).length==1)?"0"+G.toString(16):G.toString(16));
                var BB = ((B.toString(16).length==1)?"0"+B.toString(16):B.toString(16));

                return "#"+RR+GG+BB;
        }

        function(){
                        $this = $(this) ;
                        bc = $($this).parent().css('bgColor');
                        var newc = shadeColor('#'+bc, 40);
                        $('.rt').css('opacity', '0.4');
                        $($this).parent().animate({backgroundColor: '\''+newc+'\''}, 1500).css({'opacity': '1', 'cursor' : 'hand'});
                }
                ,
                function(){
                        $(this).parent().animate({backgroundColor: '\'#'+bc+'\''}, 1500);
                        $(this).css({
                                opacity: 0.8
                        });
                        $('.rt').not($this).css('opacity', '0.7');?
```


