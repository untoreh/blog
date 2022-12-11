+++
date = "11/1/2022"
title = "LLMs"
tags = ["software", "tech"]
rss_description = "Why LLMs for text are so big?"
+++

Running [gpt-6b](https://huggingface.co/EleutherAI/gpt-j-6B?text=My+name+is+Thomas+and+my+main) needs 12GB ram while [gpt-20b](https://huggingface.co/EleutherAI/gpt-neox-20b?text=My+name+is+Teven+and+I+am) even more.

Compared to [stable diffusion](https://lambdalabs.com/blog/inference-benchmark-stable-diffusion) which needs  from 3GB to 5GB.

What does influence the memory requirements to run a model? The number of parameters, since every parameter is a float (16/32/64 bits).

A picture is worth a thousands words? Are Images a better tool at compressing knowledge than languages?
Maybe. Also maybe images are more vague in general than text.

## What is a good output?
Assume the set of output is fixed (The whole universe).
We can describe an image with different phrases and all of them would be acceptable inputs, or we can accept multiple images from the same text input as valid.

Whereas to get acceptable text outputs from some text inputs it has to follow the meaning of its inputs with stricter rules. This means that fewer inputs map to the full set of outputs.

In other terms, a text-to-image LLM has a higher *surjectivity* than text-to-text LLM because of what classifies as acceptable outputs is dependent on our limitations as image "meatbags" classifiers. We consider a good output image from a text, if that image carries over the over-arching meaning of our prompt, we leave a lot to "interpretation". While when we read text, we expect it to follow strict grammatical rules, and carry meaning.

## So why is a text-to-image smaller?
We can gloss over imperfections in images because not everybody can draw and create images, whereas everybody can read and write decent prose. The utility of LLMs is reflected in our capacity to achieve the task that the LLM is built to accomplish. The less capable we are to do something, the less sophisticated the LLMs has to be to be useful, the fewer parameters it will require. In other words we are crap painters! and our bar for a "good" text-to-image model is set lower. If everybody was a really good image analyzer/producer such that our requirements for what is a good image were stricter, text-to-image models would have to be considerably bigger than text-to-text, because of how much analysis is required to truly dissect an image in all its meaning.

## Digression on what it means to understand text or images
Of course, neither text-to-image nor text-to-text LLMs carry true meaning, but it is easier to fake meaning with images than it is with text because images are an higher level of abstraction than text. Text is a serial form of communication where new information is transmitted connecting a sequence of clusters of tokens that have some meaning (call them paragraphs). 

Images instead have fractal properties, the meaning is dependent not on some known cluster at some previous position of a sequence, but on the *simultaneous* position of a multitude of clusters within a canvas.

## An algorithm to process images
To "understand" an image you have to create clusters, without knowing a particular order, only following color divergences, and classify those clusters (in entities, shapes, depth, lightning, etc), do so at each level of composition (from 1 pixels to the full canvas surface), and then assign weights across every possible relation between all the levels of clustering generated. These needs at least 3 large models, plus 1 more if you want to specialize the classification process.

This is not what stable diffusion does...in the slightest, It has a "pot" of weights (the latent space) that holds encoded (noised) information of all images it is trained on. I would say that the model use statistical properties of colors to predict an image from text (or another image). In other words, it answer the question:

> What is the most likely image which satisfies the de-noising iterations, starting from the given prompt?

This is quite the clever trick to compress a lot of information and what allows stable diffusion to fit in just 5GB of ram, whereas the method that I described earlier would require at least 3x that amount (but probably much more in practice).

## ML freedom and hardware
It is a bit sad that moore's law (or litography, if speaking about ram amounts) plateaued right when an improvement of no more than 5x would have allowed to run very effective LLMs locally on everyone machines! 

With a couple more hardware breakthroughs our computing might become much more smarter very fast.

