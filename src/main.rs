use actix_web::{web, App, HttpResponse, HttpServer, Responder};
use std::io;

#[path = "models.rs"]
mod models;

#[path = "routes.rs"]
mod routes;

#[path = "day1.rs"]
mod day1;

// Configure route
pub fn general_routes(cfg: &mut web::ServiceConfig) {
    cfg.route("/health", web::get().to(health_check_handler));
}
//Configure handler
pub async fn health_check_handler() -> impl Responder {
    HttpResponse::Ok().json("Hello. EzyTutors is alive and kicking")
}
// Instantiate and run the HTTP server
#[actix_rt::main]
async fn main() -> io::Result<()> {
    // Construct app and configure routes
    let app = move || {
        App::new()
            .configure(general_routes)
            .configure(routes::day_routes)
    };
    // Start HTTP server
    println!("Starting web server");
    HttpServer::new(app).bind("127.0.0.1:4000")?.run().await
}
