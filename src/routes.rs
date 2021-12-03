use super::day1::*;
use actix_web::web;

pub fn day_routes(cfg: &mut web::ServiceConfig) {
    cfg.service(web::scope("/day1/1").route("", web::post().to(part1)));
    cfg.service(web::scope("/day1/2").route("", web::post().to(part2)));
}
