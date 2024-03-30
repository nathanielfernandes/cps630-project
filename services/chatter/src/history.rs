pub struct History<T> {
    items: Vec<T>,
    size: usize,
    index: usize,
}

impl<T> History<T> {
    pub fn new(max_size: usize) -> Self {
        Self {
            items: Vec::with_capacity(max_size),
            index: 0,
            size: max_size,
        }
    }

    pub fn push(&mut self, item: T) {
        if self.items.len() < self.size {
            self.items.push(item);
        } else {
            self.items[self.index] = item;
            self.index = (self.index + 1) % self.size;
        }
    }

    pub fn pop(&mut self) -> Option<T> {
        if self.items.is_empty() {
            None
        } else {
            let index = self.index;
            self.index = (self.index + self.size - 1) % self.size;
            Some(self.items.remove(index))
        }
    }

    pub fn iter(&self) -> impl Iterator<Item = &T> {
        let index = self.index;
        self.items[index..].iter().chain(self.items[..index].iter())
    }

    pub fn to_vec(&self) -> Vec<T>
    where
        T: Clone,
    {
        let index = self.index;
        let mut vec = Vec::with_capacity(self.size);
        vec.extend_from_slice(&self.items[index..]);
        vec.extend_from_slice(&self.items[..index]);
        vec
    }
}
