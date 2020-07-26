const fs = require('fs-extra');
const { JSDOM } = require('jsdom');

const { size_of } = require('./shared');

const getElementContents = (dom,selector) => {
  if (dom.window.document.querySelector(selector)) {
    let contents = dom.window.document.querySelector(selector).innerHTML;
    // Fix some double escapes:
    contents = contents.replace(/&amp;([a-z]+);/g,'&$1;');
    return contents;
  }
}

const generate_chapter_featured_quote = (body) => {
  const dom = new JSDOM(body);
  const featured_quote = getElementContents(dom, '#featured-quote');
  const featured_stat_1 = getElementContents(dom,'#featured-stat-1');
  const featured_stat_label_1 = getElementContents(dom,'#featured-stat-label-1');
  const featured_stat_2 = getElementContents(dom,'#featured-stat-2');
  const featured_stat_label_2 = getElementContents(dom,'#featured-stat-label-2');
  const featured_stat_3 = getElementContents(dom,'#featured-stat-3');
  const featured_stat_label_3 = getElementContents(dom,'#featured-stat-label-3');

  let featured_quote_obj = {};
  if (featured_quote) {
    featured_quote_obj.quote = featured_quote;
  }
  if (featured_stat_1 && featured_stat_label_1) {
    featured_quote_obj.stat_1 = featured_stat_1;
    featured_quote_obj.stat_label_1 = featured_stat_label_1;
  }
  if (featured_stat_2 && featured_stat_label_2) {
    featured_quote_obj.stat_2 = featured_stat_2;
    featured_quote_obj.stat_label_2 = featured_stat_label_2;
  }
  if (featured_stat_3 && featured_stat_label_3) {
    featured_quote_obj.stat_3 = featured_stat_3;
    featured_quote_obj.stat_label_3 = featured_stat_label_3;
  }

  return featured_quote_obj;
};

const generate_featured_chapters = async (featured_quotes) => {

  console.log('Generating featured chapters')

  for (let language of Object.keys(featured_quotes)) {

    for (let year of Object.keys(featured_quotes[language])) {

      // Sort order is not guaranteed, so let's sort just to make sure no meaningless changes
      var unsorted_quotes = featured_quotes[language][year];
      var sorted_quotes = {};
      Object.keys(unsorted_quotes).sort().forEach(function(key) {
        sorted_quotes[key] = unsorted_quotes[key];
      });
      
      const json_file = `templates/${language}/${year}/featured_chapters.json`;
      
      console.log(`\n Generating ${json_file}`);
      await fs.outputFile(`${json_file}`, JSON.stringify(sorted_quotes,null,2), 'utf8');
      await size_of(`${json_file}`);

    }
  }

  return true;
};

module.exports = {
  generate_featured_chapters,
  generate_chapter_featured_quote
};
