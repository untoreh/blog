+++
date = "4/4/2021"
title = "MTR: multiple translations"
tags = ["tools"]
rss_description = "wrapping translation services for internal use"
+++

When publishing a website you might want to offer different translations. Some people don't like automated translators, I think that an automated translation is good enough, and better than nothing, and automated translators have gotten progressively better with the advances in [NLP] and [ML].

Common translation services are google, bing, yandex. These offer a free tier which we want to wrap for our own personal usage. There are also other lesser known [translation services], and some of them are shutdown at time of writing...

## Caching text

If we want to cache translations, we needed to split the requested text into smaller strings such that they are small enough to provide hits for possible future requests. The **trade-off** is that the translation of smaller sentences has less context, which lowers the quality of the translation.

How do we split incoming text such that we can reconstruct the original from the translated text is quite a trick..or a hack. We want to find a string weird enough that the translation service leaves it _as it is_ in its output. I have found variations of the **paragraph character** to work most of the times

```php
$this->misc['glue'] = ' ; ¶ ; ';
$this->misc['splitGlue'] = '/\s?;\s?¶\s?;?\s?/';
```

The `glue` string is used to concatenate **all** the strings (split from the original request) into **one** single body for the upstream translation request that we are sending to e.g. google.
The `splitGlue` is instead used to split back the received translation into the strings that we are going to cache. We see here that strings splitting isn't just useful for caching, but to **reduce the number of requests**, because in case our downstream request performs many small queries, we use our machinery to merge requests up to the maximum payload size allowed by the upstream service.

## The interface

In order to support multiple services _transparently_ I wrote an interface that settled on this api

```php
function __construct(
    Mtr &$mtr,
    Client &$gz,
    TextReq &$txtrq,
    LanguageCode &$ld
);
function translate($source, $target, $input);
function genReq(array $params);
function preReq(array &$input);
function getLangs();
```

So a service to be operational has to offer a translate function, how to translate requests, and provide the list of supported languages. With the list of supported languages we can create a matrix such that we know how many services support a specific language pairs, for parsing the [language pairs] we convert the representation returned by the service to a common `iso639-1`.

The creation of the translation instance also allows to configure the requests options used by `Guzzle` client instance such that we can for example use proxies to perform the requests. The services are [cached] after being generated the first time, this is useful since some services require to generate some initial tokens, and we don't want to regenerate them every time.

## The Go version

I also wrote a [version in golang]. The PHP version would be used by importing it in your PHP project, whereas the go version works as a standalone (micro) service.
The go version is much more verbose as it requires strict type checking and since we support querying multiple strings at once, we have to expose api that works with different input combinations, and the lacks of go generics makes the implementation very painful, but it offered concurrent processing, and was much faster in general.

## Cleaning inputs

Coupled with the translation I also built a service to [clean up html]. We whitelist some html tags and discard the rest. We also remove spam-like duplicate punctuation and unknown html attributes, and wrap links into proper anchor tags.

## Related tools

- [translators]
- [deep translator]
- [translate shell]

Self hosted:

- [apertium]
- [apache joshua]
- [argos-translate]

## Conclusions

Nowadays I think I would just use a self hosted solution, provided by either joshua or argos, since I do not aim for the best translation, I want to offer a readable translation for a website, such that it can be navigated without friction.

<!-- prettier-ignore-start-->
[NLP]: https://en.wikipedia.org/wiki/Natural_language_processing
[ML]: https://en.wikipedia.org/wiki/Machine_learning
[google]: https://translate.google.com/
[yandex]: https://translate.yandex.com/
[bing]: https://www.bing.com/translator/
[translation services]: https://web.archive.org/web/20210404064224/https://github.com/untoreh/mtr/tree/master/src/services
[language pairs]: https://en.wikipedia.org/wiki/Language_code
[cached]: https://www.php.net/manual/en/book.apcu.php
[translators]: https://github.com/UlionTse/translators
[deep translator]: https://github.com/nidhaloff/deep-translator
[translate shell]: https://github.com/soimort/translate-shell
[apertium]: https://www.apertium.org
[apache joshua]: https://github.com/apache/joshua
[argos-translate]: https://github.com/argosopentech/argos-translate
[version in golang]: https://web.archive.org/web/20201030214757/https://github.com/untoreh/mtr-go
[clean up html]: https://web.archive.org/web/20210404084244/https://github.com/untoreh/htmlcleaner

<!-- prettier-ignore-end-->
