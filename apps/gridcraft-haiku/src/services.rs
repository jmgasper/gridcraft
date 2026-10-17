//! The app's system services on air/OS: Open and Save panels (`BFilePanel`), the clipboard
//! (`BClipboard`: text and HTML), links, and making GridCraft the preferred application for
//! spreadsheets (`BMimeType`).

use std::cell::{Cell, RefCell};
use std::collections::VecDeque;
use std::path::PathBuf;
use std::rc::Rc;

use gridcraft_ui_egui::Services;

use crate::host::{self, RawEvent, kind};

/// The application's signature (also in `GridCraft.rdef`).
pub const SIGNATURE: &str = "application/x-vnd.storytold-GridCraft";

/// The spreadsheet types GridCraft opens: it becomes their preferred application on start where
/// none is set ([`claim_document_types`]), so a double-click in Tracker opens them.
const DOCUMENT_TYPES: &[&str] = &[
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    "application/vnd.ms-excel.sheet.macroEnabled.12",
    "application/vnd.ms-excel.sheet.binary.macroEnabled.12",
    "application/vnd.ms-excel",
    "application/vnd.oasis.opendocument.spreadsheet",
    "text/csv",
    "text/tab-separated-values",
];

/// What File › Open offers (the desktop app's filter).
const OPEN_EXTENSIONS: &[&str] = &["xlsx", "xlsm", "xls", "xlsb", "ods", "csv", "tsv", "txt", "json"];
/// What Insert › Pictures offers.
const PICTURE_EXTENSIONS: &[&str] = &["png", "jpg", "jpeg"];
/// The types a Save panel's suggested name may carry; anything else saves as a workbook.
const SAVE_EXTENSIONS: &[&str] = &["xlsx", "csv", "html", "pdf"];

/// Makes GridCraft the preferred application of the spreadsheet types that have none.
pub fn claim_document_types() {
    let claimed = host::claim_types(SIGNATURE, DOCUMENT_TYPES);
    if claimed > 0 {
        log::info!("preferred application for {claimed} spreadsheet types that had none");
    }
}

/// The file panels. The app asks for a path and waits for it (`Services::pick_open` returns
/// one), so the interface thread waits for the panel's answer; whatever else the window sends
/// meanwhile is kept for the shell, in order.
#[derive(Default)]
pub struct Dialogs {
    next: Cell<i32>,
    /// Events that arrived while a panel was open.
    pub deferred: RefCell<VecDeque<(RawEvent, String)>>,
    /// Paths picked in Save panels, for the shell to type once written.
    pub saved: RefCell<Vec<PathBuf>>,
}

impl Dialogs {
    fn pick(&self, save: bool, name: &str, extensions: &[&str], title: &str) -> Option<String> {
        let id = self.next.get().wrapping_add(1);
        self.next.set(id);
        host::file_panel(id, save, name, extensions, &format!("GridCraft: {title}"));
        loop {
            host::wait(None);
            while let Some((ev, text)) = host::next_event() {
                if ev.kind == kind::DIALOG_ANSWER && ev.id == id {
                    let picked = ev.x != 0.0 && !text.is_empty();
                    if picked && save {
                        self.saved.borrow_mut().push(PathBuf::from(&text));
                    }
                    return picked.then_some(text);
                }
                self.deferred.borrow_mut().push_back((ev, text));
            }
        }
    }
}

/// The Save panel's name: the suggested one, with a type GridCraft writes.
fn save_name(suggested: &str) -> String {
    let path = std::path::Path::new(suggested);
    let stem = path.file_stem().and_then(|s| s.to_str()).unwrap_or("Book1");
    let ext = path.extension().and_then(|e| e.to_str()).map(str::to_ascii_lowercase).filter(|e| SAVE_EXTENSIONS.contains(&e.as_str()));
    format!("{stem}.{}", ext.as_deref().unwrap_or("xlsx"))
}

fn clip_text(mime: &str) -> Option<String> {
    let bytes = host::clipboard_get(mime)?;
    let s = String::from_utf8_lossy(&bytes).trim_end_matches('\0').to_string();
    (!s.is_empty()).then_some(s)
}

/// The clipboard's plain text.
pub fn clipboard_text() -> Option<String> {
    clip_text("text/plain")
}

/// Opens an http, https or mailto link with its preferred application (the desktop app's
/// rule: the system never gets anything else).
fn open_link(target: &str) {
    let gridcraft_engine::links::LinkKind::External(target) = gridcraft_engine::links::classify(target) else {
        log::warn!("refused to open {target:?}: only http, https and mailto links are opened");
        return;
    };
    if !host::open_url(&target) {
        log::warn!("couldn't open {target}");
    }
}

/// The services the app gets on air/OS.
pub fn services(dialogs: Rc<Dialogs>) -> Services {
    let (open, picture, save) = (dialogs.clone(), dialogs.clone(), dialogs);
    Services {
        copy_html: Some(Box::new(
            |html, text| if host::clipboard_set(text, Some(html)) { Ok(()) } else { Err("the clipboard is unavailable".into()) },
        )),
        paste_html: Some(Box::new(|| clip_text("text/html"))),
        paste_text: Some(Box::new(clipboard_text)),
        pick_open: Some(Box::new(move || open.pick(false, "", OPEN_EXTENSIONS, "Open"))),
        pick_picture: Some(Box::new(move || picture.pick(false, "", PICTURE_EXTENSIONS, "Insert Picture"))),
        pick_save: Some(Box::new(move |suggested: &str| save.pick(true, &save_name(suggested), &[], "Save As"))),
        open_url: Some(Box::new(open_link)),
        ..Default::default()
    }
}

#[cfg(test)]
mod tests {
    use super::save_name;

    #[test]
    fn save_names_keep_a_written_type() {
        assert_eq!(save_name("Book1"), "Book1.xlsx");
        assert_eq!(save_name("/boot/home/Budget.xlsm"), "Budget.xlsx");
        assert_eq!(save_name("Report.PDF"), "Report.pdf");
        assert_eq!(save_name("data.csv"), "data.csv");
    }
}
