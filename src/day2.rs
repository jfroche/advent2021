use super::models::{Puzzle, Solution};
use actix_web::{web, HttpResponse};

pub async fn part1(puzzle: web::Json<Puzzle>) -> HttpResponse {
    let commands: (i32, i32) = puzzle
        .input
        .lines()
        .filter_map(|s| s.parse::<String>().ok())
        .map(|c| {
            let o: Vec<_> = c.split(' ').collect();
            let action = o[0].to_string();
            let quantity = o[1].parse::<i32>().unwrap();
            match action.as_ref() {
                "forward" => {
                    return (quantity, 0);
                }
                "down" => {
                    return (0, quantity);
                }
                "up" => {
                    return (0, -quantity);
                }
                _ => panic!("Invalid action"),
            }
        })
        .fold((0, 0), |mut accum, item| {
            accum.0 += item.0;
            accum.1 += item.1;
            accum
        });
    HttpResponse::Ok().json(Solution {
        raw: (commands.0 * commands.1).to_string(),
    })
}

pub async fn part2(puzzle: web::Json<Puzzle>) -> HttpResponse {
    let commands: (i32, i32, i32) = puzzle
        .input
        .lines()
        .filter_map(|s| s.parse::<String>().ok())
        .map(|c| {
            let o: Vec<_> = c.split(' ').collect();
            let action = o[0].to_string();
            let quantity = o[1].parse::<i32>().unwrap();
            match action.as_ref() {
                "forward" => {
                    return (quantity, 0);
                }
                "down" => {
                    return (0, quantity);
                }
                "up" => {
                    return (0, -quantity);
                }
                _ => panic!("Invalid action"),
            }
        })
        .fold((0, 0, 0), |mut accum, item| {
            // (depth, horizontal_position, aim)
            accum.2 += item.1;
            accum.1 += item.0;
            accum.0 += item.0 * accum.2;
            accum
        });
    HttpResponse::Ok().json(Solution {
        raw: (commands.0 * commands.1).to_string(),
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
            input: "forward 5
down 5
forward 8
up 3
down 8
forward 2"
                .into(),
        });
        let mut resp = part1(puzzle).await;
        assert_eq!(resp.status(), StatusCode::OK);
        assert!(resp.status().is_success());
        let body = resp.take_body();
        let unwrapped_body = body.as_ref().unwrap();
        assert_eq!(&Body::from(json!({ "raw": "150" })), unwrapped_body);
    }
    #[actix_rt::test]
    async fn part2_test() {
        let puzzle = web::Json(Puzzle {
            input: "forward 5
down 5
forward 8
up 3
down 8
forward 2"
                .into(),
        });
        let mut resp = part2(puzzle).await;
        assert_eq!(resp.status(), StatusCode::OK);
        assert!(resp.status().is_success());
        let body = resp.take_body();
        let unwrapped_body = body.as_ref().unwrap();
        assert_eq!(&Body::from(json!({ "raw": "900" })), unwrapped_body);
    }
}

pub fn routes(cfg: &mut web::ServiceConfig) {
    cfg.service(web::scope("/day2/1").route("", web::post().to(part1)));
    cfg.service(web::scope("/day2/2").route("", web::post().to(part2)));
}
