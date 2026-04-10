use pulldown_cmark::{html, Parser};

pub fn to_html(md: &str) -> String {
    let parser = Parser::new(md);
    let mut output = String::new();
    html::push_html(&mut output, parser);
    output
}
