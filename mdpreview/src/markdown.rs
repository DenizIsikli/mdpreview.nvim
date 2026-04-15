use pulldown_cmark::{html, Event, Options, Parser, Tag};

pub fn render_markdown(md: &str) -> String {
    let mut options = Options::empty();
    options.insert(
        Options::ENABLE_TABLES
            | Options::ENABLE_STRIKETHROUGH
            | Options::ENABLE_TASKLISTS
            | Options::ENABLE_FOOTNOTES
            | Options::ENABLE_SMART_PUNCTUATION,
    );

    let parser = Parser::new_ext(md, options);

    let mapped = parser.map(|event| match event {
        Event::Start(Tag::Image(link_type, dest, title)) => {
            let new_dest = format!("/img?path={}", dest.to_string());
            Event::Start(Tag::Image(link_type, new_dest.into(), title))
        }

        Event::Html(html) => {
            if html.contains("<img") {
                let replaced = html.replace("src=\"", "src=\"/img?path=");
                Event::Html(replaced.into())
            } else {
                Event::Html(html)
            }
        }

        _ => event,
    });

    let mut output = String::new();
    html::push_html(&mut output, mapped);
    output
}
