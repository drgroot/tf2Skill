#Scripts

A python script is used to perform all ranking related calculations. Calculations are done upon the end of the round.

#Installation

1. Place the files in the scripts folder as set in the `sm_trueskill_url` CVar. 
> For example:
>> If your `sm_trueskill_url` is set to `http://example.com/trueskill.php`
>
> then you will need to place these scripts into the root directory of your `public_html` folder or your respective folder to serve website content
>

2. Edit `config.file.sample`  with your MySQL credentials

3. Rename `config.file.sample` to `config.file`
> To test that it works, browse to the url specified in the `sm_trueskill_url` CVar. If the page doesn't show and error, then it has been successfully installed.
