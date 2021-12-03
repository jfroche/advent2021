use serde::{Deserialize, Serialize};

#[derive(Deserialize, Serialize, Debug, Clone)]
pub struct Puzzle {
    pub input: String,
}

#[derive(Deserialize, Serialize, Debug, Clone)]
pub struct Solution {
    pub raw: String,
}
