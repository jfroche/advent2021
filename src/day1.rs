use super::models::{Puzzle, Solution};
use actix_web::{web, HttpResponse};

pub async fn part1(puzzle: web::Json<Puzzle>) -> HttpResponse {
    let measurements = puzzle
        .input
        .lines()
        .filter_map(|s| s.parse::<i32>().ok())
        .collect::<Vec<_>>()
        .windows(2)
        .flat_map(<&[i32; 2]>::try_from)
        .filter(|&&[a, b]| a < b)
        .count();
    HttpResponse::Ok().json(Solution {
        raw: measurements.to_string(),
    })
}

pub async fn part2(puzzle: web::Json<Puzzle>) -> HttpResponse {
    let measurements = puzzle
        .input
        .lines()
        .filter_map(|s| s.parse::<i32>().ok())
        .collect::<Vec<_>>()
        .windows(3)
        .flat_map(<&[i32; 3]>::try_from)
        .map(|&[a, b, c]| a + b + c)
        .collect::<Vec<_>>()
        .windows(2)
        .flat_map(<&[i32; 2]>::try_from)
        .filter(|&&[a, b]| a < b)
        .count();
    HttpResponse::Ok().json(Solution {
        raw: measurements.to_string(),
    })
}
#[cfg(test)]
mod tests {
    use super::*;
    use actix_web::body::Body;
    use actix_web::http::StatusCode;
    use serde_json::json;

    #[actix_rt::test]
    async fn part1_test() {
        let puzzle = web::Json(Puzzle {
            input: "199
200
208
210
200
207
240
269
260
263"
            .into(),
        });
        let mut resp = part1(puzzle).await;
        assert_eq!(resp.status(), StatusCode::OK);
        assert!(resp.status().is_success());
        let body = resp.take_body();
        let unwrapped_body = body.as_ref().unwrap();
        assert_eq!(&Body::from(json!({ "raw": "7" })), unwrapped_body);
    }

    #[actix_rt::test]
    async fn part2_test() {
        let puzzle = web::Json(Puzzle {
            input: "199
200
208
210
200
207
240
269
260
263"
            .into(),
        });
        let mut resp = part2(puzzle).await;
        assert_eq!(resp.status(), StatusCode::OK);
        assert!(resp.status().is_success());
        let body = resp.take_body();
        let unwrapped_body = body.as_ref().unwrap();
        assert_eq!(&Body::from(json!({ "raw": "5" })), unwrapped_body);
    }
}

pub fn routes(cfg: &mut web::ServiceConfig) {
    cfg.service(web::scope("/day1/1").route("", web::post().to(part1)));
    cfg.service(web::scope("/day1/2").route("", web::post().to(part2)));
}
