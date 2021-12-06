use actix_web::{App, HttpServer};
use std::io;

#[path = "models.rs"]
mod models;

#[path = "day1.rs"]
mod day1;

#[path = "day2.rs"]
mod day2;

// Instantiate and run the HTTP server
#[actix_rt::main]
async fn main() -> io::Result<()> {
    // Construct app and configure routes
    let app = move || App::new().configure(day1::routes).configure(day2::routes);
    // Start HTTP server
    println!("Starting web server");
    HttpServer::new(app).bind("127.0.0.1:4000")?.run().await
}
