use crossterm::event::{self, Event, KeyCode, KeyEventKind};
use ratatui::{
    Frame,
    layout::{Constraint, Layout},
    style::{Color, Modifier, Style},
    widgets::{Block, List, ListItem, ListState, Paragraph},
};
use std::{
    fs, io,
    path::{Path, PathBuf},
};

#[derive(Clone)]
struct App {
    id: u64,
    name: String,
    path: PathBuf,
}

fn main() {
    let apps = scan();
    if apps.is_empty() {
        eprintln!("No Steam apps found");
        return;
    }
    if let Ok(Some(app)) = run_picker(&apps) {
        println!("{}", app.path.display());
    }
}

fn scan() -> Vec<App> {
    let mut apps = Vec::new();
    for root in find_roots() {
        let steamapps = root.join("steamapps");
        let compatdata = steamapps.join("compatdata");
        let Ok(entries) = fs::read_dir(&steamapps) else {
            continue;
        };
        for entry in entries.flatten() {
            let path = entry.path();
            if path.extension().is_some_and(|e| e == "acf")
                && let Some(app) = parse_acf(&path, &compatdata)
            {
                apps.push(app);
            }
        }
    }
    apps.sort_by(|a, b| a.name.to_lowercase().cmp(&b.name.to_lowercase()));
    apps
}

fn find_roots() -> Vec<PathBuf> {
    let mut roots = Vec::new();
    let Some(home) = dirs::home_dir() else {
        return roots;
    };
    for c in [home.join(".steam/steam"), home.join(".local/share/Steam")] {
        if let Ok(p) = fs::canonicalize(&c)
            && !roots.contains(&p)
        {
            roots.push(p.clone());
            if let Ok(content) = fs::read_to_string(p.join("steamapps/libraryfolders.vdf")) {
                for line in content.lines() {
                    if line.trim().starts_with("\"path\"")
                        && let Some(path) = line.split('"').nth(3)
                        && let Ok(lp) = fs::canonicalize(path)
                        && !roots.contains(&lp)
                    {
                        roots.push(lp);
                    }
                }
            }
        }
    }
    roots
}

fn parse_acf(path: &Path, compatdata: &Path) -> Option<App> {
    let content = fs::read_to_string(path).ok()?;
    let mut id = None;
    let mut name = None;
    for line in content.lines() {
        let parts: Vec<&str> = line.trim().split('"').collect();
        if parts.len() >= 4 {
            match parts[1] {
                "appid" => id = parts[3].parse().ok(),
                "name" => name = Some(parts[3].to_string()),
                _ => {}
            }
        }
    }
    Some(App {
        id: id?,
        name: name?,
        path: compatdata.join(id?.to_string()),
    })
}

fn run_picker(apps: &[App]) -> io::Result<Option<App>> {
    let mut terminal = ratatui::init();
    let mut state = ListState::default().with_selected(Some(0));
    let mut filter = String::new();

    let result = loop {
        let filtered: Vec<&App> = apps
            .iter()
            .filter(|a| a.name.to_lowercase().contains(&filter.to_lowercase()))
            .collect();

        terminal.draw(|f| draw(f, &filtered, &mut state, &filter))?;

        if let Event::Key(key) = event::read()? {
            if key.kind != KeyEventKind::Press {
                continue;
            }
            match key.code {
                KeyCode::Esc => break None,
                KeyCode::Enter => {
                    break state
                        .selected()
                        .and_then(|i| filtered.get(i).cloned())
                        .cloned();
                }
                KeyCode::Up | KeyCode::Char('k') if filter.is_empty() => {
                    state.select(Some(state.selected().unwrap_or(0).saturating_sub(1)));
                }
                KeyCode::Down | KeyCode::Char('j') if filter.is_empty() => {
                    let i = state.selected().unwrap_or(0);
                    state.select(Some((i + 1).min(filtered.len().saturating_sub(1))));
                }
                KeyCode::Char(c) => {
                    filter.push(c);
                    state.select(Some(0));
                }
                KeyCode::Backspace => {
                    filter.pop();
                    state.select(Some(0));
                }
                _ => {}
            }
        }
    };

    ratatui::restore();
    Ok(result)
}

fn draw(f: &mut Frame, apps: &[&App], state: &mut ListState, filter: &str) {
    let [search, list] =
        Layout::vertical([Constraint::Length(3), Constraint::Min(0)]).areas(f.area());
    f.render_widget(
        Paragraph::new(filter).block(Block::bordered().title(" Search ")),
        search,
    );
    let items: Vec<ListItem> = apps
        .iter()
        .map(|a| ListItem::new(format!("[{}] {}", a.id, a.name)))
        .collect();
    f.render_stateful_widget(
        List::new(items)
            .block(Block::bordered().title(format!(" Games ({}) ", apps.len())))
            .highlight_style(
                Style::default()
                    .add_modifier(Modifier::REVERSED)
                    .fg(Color::Cyan),
            )
            .highlight_symbol("> "),
        list,
        state,
    );
}
