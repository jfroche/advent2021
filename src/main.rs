use actix_web::{middleware::Logger, App, HttpServer};
use env_logger::Env;
use log::info;
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
    //env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));
    env_logger::from_env(Env::default().filter("ADVENT_LOG"))
        .format_timestamp_millis()
        .init();
    // Construct app and configure routes
    let app = move || {
        App::new()
            .configure(day1::routes)
            .configure(day2::routes)
            .wrap(Logger::default())
    };
    // Start HTTP server
    info!("Starting web server");
    HttpServer::new(app).bind("127.0.0.1:4000")?.run().await
}
