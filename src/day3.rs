use super::models::{Puzzle, Solution};
use actix_web::{web, HttpResponse};
use log::debug;

pub async fn part1(puzzle: web::Json<Puzzle>) -> HttpResponse {
    let puzzle_size = puzzle.input.lines().count();
    let report: Vec<u32> = puzzle
        .input
        .lines()
        .filter_map(|s| s.parse::<String>().ok())
        .map(|s| {
            s.chars()
                .map(|c| c.to_string().parse::<u32>().unwrap())
                .collect()
        })
        .fold(Vec::new(), |mut accum, item: Vec<u32>| {
            item.iter().enumerate().for_each(|(i, x)| {
                if accum.len() <= i {
                    accum.push(*x)
                } else {
                    accum[i] += *x
                }
            });
            accum
        });
    let gamma_rate_binary: String = report.iter().fold(String::from(""), |mut accum, column| {
        if (*column as usize) > (puzzle_size - (*column as usize)) {
            accum.push_str("1")
        } else {
            accum.push_str("0")
        }
        accum
    });
    debug!("Gamma binary {}", gamma_rate_binary);
    let epsilon_rate_binary: String = gamma_rate_binary
        .chars()
        .map(|c| match c {
            '0' => '1',
            '1' => '0',
            _ => panic!("Wrong gamma binary format"),
        })
        .collect();
    debug!("Epsilon binary {}", epsilon_rate_binary);
    let gamma_rate = isize::from_str_radix(gamma_rate_binary.as_str(), 2).unwrap();
    debug!("Gamma {}", gamma_rate);
    let epsilon_rate = isize::from_str_radix(epsilon_rate_binary.as_str(), 2).unwrap();
    debug!("Epsilon {}", epsilon_rate);
    HttpResponse::Ok().json(Solution {
        raw: (gamma_rate * epsilon_rate).to_string(),
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
        env_logger::builder().init();
        let puzzle = web::Json(Puzzle {
            input: "00100
11110
10110
10111
10101
01111
00111
11100
10000
11001
00010
01010"
                .into(),
        });
        let mut resp = part1(puzzle).await;
        assert_eq!(resp.status(), StatusCode::OK);
        assert!(resp.status().is_success());
        let body = resp.take_body();
        let unwrapped_body = body.as_ref().unwrap();
        assert_eq!(&Body::from(json!({ "raw": "198" })), unwrapped_body);
    }
}

pub fn routes(cfg: &mut web::ServiceConfig) {
    cfg.service(web::scope("/day3/1").route("", web::post().to(part1)));
    //cfg.service(web::scope("/day3/2").route("", web::post().to(part2)));
}
